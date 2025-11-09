import SwiftUI
import ARKit
import RealityKit
import AVFoundation
// 安全なARビューコンテナ
struct ARViewContainer: UIViewRepresentable {
    let fileName: String
    @ObservedObject private var arStateManager = ARStateManager.shared
    
    func makeUIView(context: Context) -> UIView {
        // AR対応の最終チェック
        guard ARWorldTrackingConfiguration.isSupported else {
            print("AR not supported")
            return createFallbackView()
        }
        
        let arView = ARView(frame: .zero)
        
        // 拡張AR設定
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        
        // ワールドマップ保存機能を有効化
        if ARWorldTrackingConfiguration.supportsUserFaceTracking {
            config.userFaceTrackingEnabled = false
        }
        
        // 保存されたワールドマップがあれば復元
        if let savedWorldMap = context.coordinator.arStateManager?.getSavedWorldMap() {
            config.initialWorldMap = savedWorldMap
            print("保存されたワールドマップを復元")
        }
        
        // セッション開始を安全に実行
        DispatchQueue.main.async {
            arView.session.run(config, options: [])
        }
        
        // タップジェスチャーを追加
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tapGesture)
        
        context.coordinator.arView = arView
        context.coordinator.fileName = fileName
        context.coordinator.arStateManager = arStateManager
        
        // ARセッションデリゲートを設定
        arView.session.delegate = context.coordinator
        
        return arView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // ファイル名が変更されたかチェック
        if context.coordinator.fileName != fileName {
            print("ファイル名が変更されました: \(context.coordinator.fileName) -> \(fileName)")
            context.coordinator.fileName = fileName
            
            // 既存のモデルを削除して新しいモデルを準備
            context.coordinator.removeCurrentModel()
            
            // 次回のタップで新しいモデルが配置されることをログ出力
            print("新しいモデル準備完了: \(fileName)")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(fileName: fileName)
    }
    
    private func createFallbackView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.systemGray5
        
        let label = UILabel()
        label.text = "AR非対応"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var arView: ARView?
        var fileName: String {
            didSet {
                if oldValue != fileName {
                    print("Coordinator: fileName更新 \(oldValue) -> \(fileName)")
                }
            }
        }
        var currentAnchor: AnchorEntity?
        var currentAnimationController: AnimationPlaybackController?
        var arStateManager: ARStateManager?
        private var worldMapSaveTimer: Timer?
        private var lastPlacedModelName: String?
        
        init(fileName: String) {
            self.fileName = fileName
            super.init()
            
            // 定期的にワールドマップを保存
            startWorldMapSaving()
        }
        
        deinit {
            worldMapSaveTimer?.invalidate()
        }
        
        private func startWorldMapSaving() {
            // 30秒ごとにワールドマップを保存
            worldMapSaveTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
                self?.saveCurrentWorldMap()
            }
        }
        
        private func saveCurrentWorldMap() {
            guard let arView = arView else { return }
            
            arView.session.getCurrentWorldMap { [weak self] worldMap, error in
                if let error = error {
                    print("ワールドマップ保存エラー: \(error)")
                    return
                }
                
                if let worldMap = worldMap {
                    self?.arStateManager?.saveWorldMap(worldMap)
                    print("ワールドマップを保存しました")
                }
            }
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView else {
                print("ARView not available")
                return
            }
            
            let location = gesture.location(in: arView)
            
            // 既に同じモデルが配置されている場合は何もしない
            if let lastPlaced = lastPlacedModelName, lastPlaced == fileName,
               let stateManager = arStateManager, stateManager.isModelPlaced(fileName: fileName) {
                print("同じモデルが既に配置済み")
                return
            }
            
            // 保存された配置位置があるかチェック
            if let savedTransform = arStateManager?.getPlacementTransform(fileName: fileName),
               let lastPlaced = lastPlacedModelName, lastPlaced == fileName {
                print("保存された位置にモデルを復元")
                placeModel(at: savedTransform, in: arView)
                return
            }
            
            // 平面検出を試行
            let results = arView.raycast(
                from: location,
                allowing: .estimatedPlane,
                alignment: .horizontal
            )
            
            if let firstResult = results.first {
                placeModel(at: firstResult.worldTransform, in: arView)
            } else {
                // 平面が見つからない場合は固定位置に配置
                placeModelAtDefaultPosition(in: arView)
            }
        }
        
        private func placeModel(at transform: simd_float4x4, in arView: ARView) {
            // 既存のモデルを削除
            removeCurrentModel()
            
            let cleanFileName = fileName.replacingOccurrences(of: ".usdz", with: "")
            print("モデル配置試行: \(cleanFileName)")
            
            // USDZファイルの確認
            guard let modelURL = Bundle.main.url(forResource: cleanFileName, withExtension: "usdz") else {
                print("USDZファイルが見つかりません: \(cleanFileName).usdz")
                placeFallbackModel(at: transform, in: arView)
                return
            }
            
            // 非同期でモデル読み込み
            Task {
                await loadModel(from: modelURL, at: transform, in: arView)
            }
        }
        
        private func placeModelAtDefaultPosition(in arView: ARView) {
            // カメラの前方1メートルに配置
            guard let frame = arView.session.currentFrame else {
                print("カメラフレームが取得できません")
                return
            }
            
            var transform = frame.camera.transform
            transform.columns.3.z -= 1.0 // 1メートル前方
            transform.columns.3.y -= 0.3 // 少し下に
            
            placeModel(at: transform, in: arView)
        }
        
        @MainActor
        private func loadModel(from url: URL, at transform: simd_float4x4, in arView: ARView) async {
            do {
                // モデル読み込み
                let entity = try await ModelEntity(contentsOf: url)
                
                // 安全なスケール設定
                entity.scale = [0.1, 0.1, 0.1]
                
                // アンカー作成
                let anchor = AnchorEntity(world: transform)
                anchor.addChild(entity)
                
                // シーンに追加
                arView.scene.addAnchor(anchor)
                currentAnchor = anchor
                
                // 状態を保存
                arStateManager?.setModelPlaced(fileName: fileName, at: transform)
                lastPlacedModelName = fileName
                
                print("モデルを配置: \(url.lastPathComponent)")
                print("配置位置を保存: \(transform.columns.3)")
                
                // アニメーションを自動再生
                playAnimationsIfAvailable(for: entity)
                
            } catch {
                print("モデル読み込みエラー: \(error)")
                // エラー時はフォールバックモデルを配置
                placeFallbackModel(at: transform, in: arView)
            }
        }
        
        private func playAnimationsIfAvailable(for entity: ModelEntity) {
            // モデルに含まれるアニメーションを検索
            let animations = entity.availableAnimations
            
            if animations.isEmpty {
                print("アニメーションが見つかりません")
                return
            }
            
            print("利用可能なアニメーション数: \(animations.count)")
            
            // 最初のアニメーションを再生（複数ある場合は最初のもの）
            if let firstAnimation = animations.first {
                print("アニメーションを再生: \(firstAnimation.name ?? "名前なし")")
                
                // アニメーションを無限ループで再生
                currentAnimationController = entity.playAnimation(
                    firstAnimation.repeat(duration: .infinity),
                    transitionDuration: 0.5,
                    startsPaused: false
                )
                
                // アニメーション速度を調整
                currentAnimationController?.speed = 1.0
            }
        }
        
        private func placeFallbackModel(at transform: simd_float4x4, in arView: ARView) {
            // シンプルなキューブを配置
            let mesh = MeshResource.generateBox(size: 0.1)
            let material = SimpleMaterial(color: .systemBlue, isMetallic: false)
            let entity = ModelEntity(mesh: mesh, materials: [material])
            
            let anchor = AnchorEntity(world: transform)
            anchor.addChild(entity)
            
            arView.scene.addAnchor(anchor)
            currentAnchor = anchor
            
            print("フォールバックモデルを配置")
        }
        
        func removeCurrentModel() {
            if let currentAnchor = currentAnchor {
                // アニメーションを停止
                stopCurrentAnimations()
                
                currentAnchor.removeFromParent()
                self.currentAnchor = nil
                print("既存のモデルを削除")
            }
        }
        
        func clearAllAnchors() {
            removeCurrentModel()
            arStateManager?.clearModelPlacement(fileName: fileName)
            lastPlacedModelName = nil
            print("全てのアンカーをクリア")
        }
        
        // MARK: - ARSessionDelegate
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // フレーム更新時の処理（必要に応じて実装）
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            print("アンカーが追加されました: \(anchors.count)")
        }
        
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            // アンカー更新時の処理
        }
        
        func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
            print("アンカーが削除されました: \(anchors.count)")
        }
        
        func sessionWasInterrupted(_ session: ARSession) {
            print("ARセッションが中断されました")
        }
        
        func sessionInterruptionEnded(_ session: ARSession) {
            print("ARセッションの中断が終了しました")
            
            // セッション再開時に保存されたワールドマップがあれば復元を試行
            if let savedWorldMap = arStateManager?.getSavedWorldMap() {
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
        
        private func stopCurrentAnimations() {
            // 現在のアニメーションコントローラーを停止
            currentAnimationController?.stop()
            currentAnimationController = nil
            
            // アンカー内の全てのModelEntityのアニメーションを停止
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
        
        func restartAnimations() {
            guard let anchor = currentAnchor else { return }
            
            // ModelEntityを再帰的に検索してアニメーションを再開
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
    }
}
