import SwiftUI
import ARKit
import RealityKit
import AVFoundation

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

