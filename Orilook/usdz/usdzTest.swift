import SwiftUI
import SceneKit

struct MinimalUSDZViewer: View {
    var body: some View {
        SceneView()
            .frame(maxWidth: 400, maxHeight: 400)
            .edgesIgnoringSafeArea(.all)
    }
}

struct SceneView: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        
        // 基本設定
        scnView.allowsCameraControl = true
        scnView.backgroundColor = UIColor.systemBackground
        
        // シーンを作成
        let scene = SCNScene()
        scnView.scene = scene
        
        // USDZファイルを読み込み（ファイル名を実際のファイル名に変更してください）
        loadUSDZModel(scene: scene, fileName: "paper_airplane")
        
        // 基本的なライティング
        setupBasicLighting(scene: scene)
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // 更新処理（必要に応じて）
    }
    
    private func loadUSDZModel(scene: SCNScene, fileName: String) {
        // Bundle内のUSDZファイルを読み込み
        guard let modelURL = Bundle.main.url(forResource: fileName, withExtension: "usdz") else {
            print("USDZファイルが見つかりません: \(fileName).usdz")
            return
        }
        
        do {
            // USDZファイルをシーンとして読み込み
            let modelScene = try SCNScene(url: modelURL)
            
            // モデルをシーンに追加
            for child in modelScene.rootNode.childNodes {
                scene.rootNode.addChildNode(child)
            }
            
            print("USDZファイルの読み込みが完了しました")
            
        } catch {
            print("USDZファイルの読み込みに失敗しました: \(error)")
        }
    }
    
    private func setupBasicLighting(scene: SCNScene) {
        // 環境光を追加
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor.white
        ambientLight.intensity = 300
        
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)
        
        // 指向性ライトを追加
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.color = UIColor.white
        directionalLight.intensity = 800
        
        let directionalNode = SCNNode()
        directionalNode.light = directionalLight
        directionalNode.position = SCNVector3(5, 5, 5)
        scene.rootNode.addChildNode(directionalNode)
    }
}

#Preview {
    MinimalUSDZViewer()
}
