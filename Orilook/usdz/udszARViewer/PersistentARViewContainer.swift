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
        
        // AR設定
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        if ARWorldTrackingConfiguration.supportsUserFaceTracking {
            config.userFaceTrackingEnabled = false
        }
        
        // 保存されたワールドマップがあれば復元
        if let savedWorldMap = arStateManager.getSavedWorldMap() {
            config.initialWorldMap = savedWorldMap
            print("保存されたワールドマップを復元")
        }
        
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
        arView.session.delegate = context.coordinator
        
        let sessionId = UIDevice.current.identifierForVendor?.uuidString ?? "default"
        arStateManager.setCurrentSession(sessionId)
        
        // ✅ 既存のアンカー位置を復元
        if let savedTransform = arStateManager.getPlacementTransform(fileName: "session_anchor") {
            print("既存のアンカー位置を検出、2秒後に自動復元")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                Task { @MainActor in // ✅ 修正: Task内で @MainActor を明示
                    context.coordinator.restoreAnchor(at: savedTransform, in: arView)
                }
            }
        }
        
        return arView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // ✅ ファイル名が変更されたら、CoordinatorのswapModelを呼ぶ
        if context.coordinator.fileName != fileName {
            print("updateUIView: ファイル名が変更されました: \(context.coordinator.fileName) -> \(fileName)")
            
            Task { @MainActor in // ✅ 修正: Task内で @MainActor を明示
                context.coordinator.swapModel(to: fileName)
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
