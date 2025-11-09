import SwiftUI
import ARKit
import RealityKit
import AVFoundation

// AR状態管理クラス（シングルトン）
class ARStateManager: ObservableObject {
    static let shared = ARStateManager()
    
    @Published var modelStates: [String: ModelState] = [:]
    private(set) var savedWorldMap: ARWorldMap?
    private var currentSessionId: String?
    
    private init() {}
    
    struct ModelState {
        var isPlaced: Bool = false
        var placementTransform: simd_float4x4?
        var sessionId: String?
    }
    
    func saveWorldMap(_ worldMap: ARWorldMap) {
        savedWorldMap = worldMap
        print("ワールドマップを保存: anchors=\(worldMap.anchors.count)")
    }
    
    func getSavedWorldMap() -> ARWorldMap? {
        return savedWorldMap
    }
    
    func setCurrentSession(_ sessionId: String) {
        currentSessionId = sessionId
        print("ARセッションID設定: \(sessionId)")
    }
    
    func setModelPlaced(fileName: String, at transform: simd_float4x4) {
        let state = ModelState(
            isPlaced: true,
            placementTransform: transform,
            sessionId: currentSessionId
        )
        modelStates[fileName] = state
        print("モデル配置状態を保存: \(fileName) at \(transform.columns.3)")
    }
    
    func getModelState(fileName: String) -> ModelState? {
        return modelStates[fileName]
    }
    
    func isModelPlaced(fileName: String) -> Bool {
        return modelStates[fileName]?.isPlaced ?? false
    }
    
    func getPlacementTransform(fileName: String) -> simd_float4x4? {
        return modelStates[fileName]?.placementTransform
    }
    
    func clearModelPlacement(fileName: String) {
        modelStates[fileName] = nil
        print("モデル配置状態をクリア: \(fileName)")
    }
    
    func clearAllModelPlacements() {
        modelStates.removeAll()
        savedWorldMap = nil
        print("全モデル配置状態とワールドマップをクリア")
    }
}

// 最も安全なARビューア
struct ARUSDZViewer: View {
    let fileName: String
    let width: CGFloat
    let height: CGFloat
    
    init(_ fileName: String, width: CGFloat = 300, height: CGFloat = 400) {
        self.fileName = fileName
        self.width = width
        self.height = height
    }
    
    var body: some View {
        Group {
            if isARSupported() {
                ARViewContainer(fileName: fileName)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        ARControlsOverlay(),
                        alignment: .topTrailing
                    )
                    .id(fileName) // 重要: fileNameが変更されたらビューを再作成
            } else {
                // AR非対応時の代替表示
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: width, height: height)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundColor(.orange)
                            Text("AR非対応")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("このデバイスではARが利用できません")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private func isARSupported() -> Bool {
        return ARWorldTrackingConfiguration.isSupported
    }
}

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

// 永続化対応ARビューア
struct PersistentARUSDZViewer: View {
    let fileName: String
    let width: CGFloat
    let height: CGFloat
    @ObservedObject private var arStateManager = ARStateManager.shared
    
    init(fileName: String, width: CGFloat = 300, height: CGFloat = 400) {
        self.fileName = fileName
        self.width = width
        self.height = height
    }
    
    var body: some View {
        Group {
            if isARSupported() {
                PersistentARViewContainer(fileName: fileName)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        EnhancedARControlsOverlay(fileName: fileName),
                        alignment: .topTrailing
                    )
                    .id(fileName) // 重要: fileNameが変更されたらビューを再作成
            } else {
                // AR非対応時の代替表示
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: width, height: height)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundColor(.orange)
                            Text("AR非対応")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("このデバイスではARが利用できません")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private func isARSupported() -> Bool {
        return ARWorldTrackingConfiguration.isSupported
    }
}

// 永続化対応ARビューコンテナ
struct PersistentARViewContainer: UIViewRepresentable {
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
        if let savedWorldMap = arStateManager.getSavedWorldMap() {
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
            action: #selector(PersistentCoordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tapGesture)
        
        context.coordinator.arView = arView
        context.coordinator.fileName = fileName
        context.coordinator.arStateManager = arStateManager
        
        // ARセッションデリゲートを設定
        arView.session.delegate = context.coordinator
        
        // セッションIDを設定（デバイス固有）
        let sessionId = UIDevice.current.identifierForVendor?.uuidString ?? "default"
        arStateManager.setCurrentSession(sessionId)
        
        // 既に配置されたモデルがある場合は自動復元
        if let savedTransform = arStateManager.getPlacementTransform(fileName: fileName) {
            print("既存の配置位置を検出、2秒後に自動復元: \(fileName)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                context.coordinator.placeModel(at: savedTransform, in: arView)
            }
        }
        
        return arView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // ファイル名が変更されたかチェック
        if context.coordinator.fileName != fileName {
            print("ファイル名が変更されました: \(context.coordinator.fileName) -> \(fileName)")
            let _ = context.coordinator.fileName
            context.coordinator.fileName = fileName
            
            // 既存のモデルを削除
            context.coordinator.removeCurrentModel()
            
            // 新しいモデルの保存された位置があるかチェックして即座に復元
            if let savedTransform = arStateManager.getPlacementTransform(fileName: fileName),
               let arView = uiView as? ARView {
                print("ステップ変更後に既存位置を検出、即座に復元: \(fileName)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    context.coordinator.placeModel(at: savedTransform, in: arView)
                }
            } else {
                print("新しいモデル準備完了（配置なし）: \(fileName)")
            }
        }
    }
    
    func makeCoordinator() -> PersistentCoordinator {
        PersistentCoordinator(fileName: fileName, arStateManager: arStateManager)
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
}

// 永続化対応Coordinator
class PersistentCoordinator: NSObject, ARSessionDelegate {
    var arView: ARView?
    var fileName: String {
        didSet {
            if oldValue != fileName {
                print("PersistentCoordinator: fileName更新 \(oldValue) -> \(fileName)")
            }
        }
    }
    var currentAnchor: AnchorEntity?
    var currentAnimationController: AnimationPlaybackController?
    var arStateManager: ARStateManager
    private var worldMapSaveTimer: Timer?
    private var lastPlacedModelName: String?
    
    init(fileName: String, arStateManager: ARStateManager) {
        self.fileName = fileName
        self.arStateManager = arStateManager
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
                self?.arStateManager.saveWorldMap(worldMap)
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
        if arStateManager.isModelPlaced(fileName: fileName) {
            print("同じモデルが既に配置済み: \(fileName)")
            return
        }
        
        // 保存された配置位置があるかチェック
        if let savedTransform = arStateManager.getPlacementTransform(fileName: fileName) {
            print("保存された位置にモデルを復元: \(fileName)")
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
    
    func placeModel(at transform: simd_float4x4, in arView: ARView) {
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
            
            // 状態を保存（ファイル名ベース）
            arStateManager.setModelPlaced(fileName: fileName, at: transform)
            lastPlacedModelName = fileName
            
            print("モデルを配置: \(url.lastPathComponent)")
            print("配置位置を保存: \(fileName) at \(transform.columns.3)")
            
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
        
        // 状態を保存（ファイル名ベース）
        arStateManager.setModelPlaced(fileName: fileName, at: transform)
        lastPlacedModelName = fileName
        
        print("フォールバックモデルを配置: \(fileName)")
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
        arStateManager.clearModelPlacement(fileName: fileName)
        lastPlacedModelName = nil
        print("全てのアンカーをクリア: \(fileName)")
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
            // 配置状態の表示
            if arStateManager.isModelPlaced(fileName: fileName) {
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
                // タップ操作の説明
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
            
            // リセットボタン
            Button(action: {
                arStateManager.clearModelPlacement(fileName: fileName)
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

// アニメーション制御付きのコントロールオーバーレイ
struct ARControlsOverlay: View {
    @State private var isAnimationPaused = false
    
    var body: some View {
        VStack(spacing: 8) {
            // タップ操作の説明
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
            
            // アニメーション制御ボタン
            Button(action: {
                // 注意: この実装では実際のアニメーション制御は行われません
                // 実際のアプリではCoordinatorへの参照が必要です
                isAnimationPaused.toggle()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: isAnimationPaused ? "play.fill" : "pause.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    Text(isAnimationPaused ? "再生" : "停止")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
                .padding(6)
                .background(Color.black.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(8)
    }
}
