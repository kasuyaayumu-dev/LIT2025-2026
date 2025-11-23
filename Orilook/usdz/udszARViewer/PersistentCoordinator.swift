import SwiftUI
import ARKit
import RealityKit
import AVFoundation
import Combine

// 永続化対応Coordinator
class PersistentCoordinator: NSObject, ARSessionDelegate {
    var arView: ARView?
    var fileName: String
    var currentAnchor: AnchorEntity?
    var currentAnimationController: AnimationPlaybackController?
    var arStateManager: ARStateManager
    private var worldMapSaveTimer: Timer?
    private var lastPlacedModelName: String?
    
    private var resetCancellable: AnyCancellable?
    
    init(fileName: String, arStateManager: ARStateManager) {
        self.fileName = fileName
        self.arStateManager = arStateManager
        super.init()
        
        startWorldMapSaving()
        setupResetObserver()
    }
    
    deinit {
        worldMapSaveTimer?.invalidate()
        resetCancellable?.cancel()
    }
    
    private func setupResetObserver() {
        resetCancellable = arStateManager.$resetTrigger
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in // ✅ 修正: @MainActor を削除
                Task { @MainActor in
                    print("Coordinator: リセットトリガー受信")
                    self?.clearAllAnchors()
                }
            }
    }
    
    private func startWorldMapSaving() {
        worldMapSaveTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.saveCurrentWorldMap()
        }
    }
    
    private func saveCurrentWorldMap() {
        guard let arView = arView else { return }
        arView.session.getCurrentWorldMap { [weak self] worldMap, error in
            if let worldMap = worldMap {
                self?.arStateManager.saveWorldMap(worldMap)
                print("ワールドマップを保存しました")
            }
        }
    }
    
    @MainActor
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let arView = arView else { return }
        
        if currentAnchor != nil {
            print("handleTap: 既にアンカーが配置済みです。")
            return
        }
        
        let location = gesture.location(in: arView)
        let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
        
        if let firstResult = results.first {
            let transform = firstResult.worldTransform
            
            print("handleTap: 新しいアンカーを作成・保持します。")
            let anchor = AnchorEntity(world: transform)
            arView.scene.addAnchor(anchor)
            self.currentAnchor = anchor
            
            arStateManager.setModelPlaced(fileName: "session_anchor", at: transform)
            
            loadModel(named: self.fileName, into: anchor)
            
        } else {
            print("平面が見つかりませんでした。")
        }
    }

    @MainActor
    func restoreAnchor(at transform: simd_float4x4, in arView: ARView) {
        if currentAnchor != nil {
            print("restoreAnchor: 既にアンカーが存在します。")
            return
        }
        
        print("restoreAnchor: 保存された位置にアンカーを復元します。")
        let anchor = AnchorEntity(world: transform)
        arView.scene.addAnchor(anchor)
        self.currentAnchor = anchor
        
        arStateManager.setModelPlaced(fileName: "session_anchor", at: transform)
        
        loadModel(named: self.fileName, into: anchor)
    }

    @MainActor
    func swapModel(to newFileName: String) {
        self.fileName = newFileName
        
        guard let anchor = self.currentAnchor else {
            print("swapModel: アンカーがまだ配置されていません。")
            return
        }
        
        removeCurrentModel()
        
        print("swapModel: \(newFileName) をロードします。")
        loadModel(named: newFileName, into: anchor)
    }
    
    @MainActor
    private func loadModel(named modelName: String, into anchor: AnchorEntity) {
        let cleanFileName = modelName.replacingOccurrences(of: ".usdz", with: "")
        
        guard let modelURL = Bundle.main.url(forResource: cleanFileName, withExtension: "usdz") else {
            print("USDZファイルが見つかりません: \(cleanFileName).usdz")
            placeFallbackModel(into: anchor)
            return
        }
        
        Task {
            do {
                let entity = try await ModelEntity(contentsOf: modelURL)
                
                await MainActor.run {
                    entity.scale = [0.1, 0.1, 0.1]
                    anchor.addChild(entity)
                    print("モデルを配置: \(modelURL.lastPathComponent)")
                    playAnimationsIfAvailable(for: entity)
                }
                
            } catch {
                print("モデル読み込みエラー: \(error)")
                await MainActor.run {
                    placeFallbackModel(into: anchor)
                }
            }
        }
    }
    
    @MainActor
    private func placeFallbackModel(into anchor: AnchorEntity) {
        let mesh = MeshResource.generateBox(size: 0.1)
        let material = SimpleMaterial(color: .systemBlue, isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        
        anchor.addChild(entity)
        
        print("フォールバックモデルを配置")
    }
    
    @MainActor
    func removeCurrentModel() {
        if let anchor = currentAnchor {
            stopCurrentAnimations()
            anchor.children.removeAll()
            print("既存のモデル(アンカーの子)を削除")
        }
    }
    
    @MainActor
    func clearAllAnchors() {
        if let anchor = currentAnchor {
            stopCurrentAnimations()
            anchor.removeFromParent()
            self.currentAnchor = nil
            print("アンカーをシーンから削除")
        }
        
        arStateManager.clearModelPlacement(fileName: "session_anchor")
        lastPlacedModelName = nil
        print("全てのアンカーと状態をクリア")
    }
    
    @MainActor
    private func stopCurrentAnimations() {
        currentAnimationController?.stop()
        currentAnimationController = nil
        
        guard let anchor = currentAnchor else { return }
        
        func stopAnimationsRecursively(_ entity: Entity) {
            if let modelEntity = entity as? ModelEntity {
                modelEntity.stopAllAnimations()
            }
            for child in entity.children {
                stopAnimationsRecursively(child)
            }
        }
        
        stopAnimationsRecursively(anchor)
        print("アニメーションを停止")
    }
    
    @MainActor
    private func playAnimationsIfAvailable(for entity: ModelEntity) {
        let animations = entity.availableAnimations
        
        if animations.isEmpty {
            print("アニメーションが見つかりません")
            return
        }
        
        print("利用可能なアニメーション数: \(animations.count)")
        
        if let firstAnimation = animations.first {
            print("アニメーションを再生: \(firstAnimation.name ?? "名前なし")")
            currentAnimationController = entity.playAnimation(
                firstAnimation.repeat(duration: .infinity),
                transitionDuration: 0.5,
                startsPaused: false
            )
            currentAnimationController?.speed = 1.0
        }
    }
    
    @MainActor
    func restartAnimations() {
        guard let anchor = currentAnchor else { return }
        
        func restartAnimationsRecursively(_ entity: Entity) {
            if let modelEntity = entity as? ModelEntity {
                playAnimationsIfAvailable(for: modelEntity)
            }
            for child in entity.children {
                restartAnimationsRecursively(child)
            }
        }
        
        restartAnimationsRecursively(anchor)
        print("アニメーションを再開")
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {}
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        print("アンカーが追加されました: \(anchors.count)")
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {}
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        print("アンカーが削除されました: \(anchors.count)")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("ARセッションが中断されました")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("ARセッションの中断が終了しました")
        if let savedWorldMap = arStateManager.getSavedWorldMap() {
            let config = ARWorldTrackingConfiguration()
            config.planeDetection = [.horizontal]
            config.initialWorldMap = savedWorldMap
            
            session.run(config, options: [.resetTracking, .removeExistingAnchors])
            print("保存されたワールドマップで再開")
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("ARセッションエラー: \(error)")
    }
}

// 拡張されたARコントロールオーバーレイ
struct EnhancedARControlsOverlay: View {
    let fileName: String
    @ObservedObject private var arStateManager = ARStateManager.shared
    @State private var isAnimationPaused = false
    
    var body: some View {
        VStack(spacing: 8) {
            
            if arStateManager.isModelPlaced(fileName: "session_anchor") {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    Text("配置済み")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(8)
                .background(Color.black.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "hand.tap")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("タップ")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(8)
                .background(Color.black.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            Button(action: {
                arStateManager.resetTrigger = UUID()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    Text("リセット")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
                .padding(6)
                .background(Color.red.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(8)
    }
}
