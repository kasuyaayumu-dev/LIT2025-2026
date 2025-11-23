import SwiftUI
import SceneKit

// 修正版：1行で使えるUSDZビューアコンポーネント
struct USDZViewer3D: View {
    let fileName: String  // @Stateを削除してletに変更
    let width: CGFloat
    let height: CGFloat
    
    // 初期化  
    init(_ fileName: String, width: CGFloat = 300, height: CGFloat = 300) {
        self.fileName = fileName
        self.width = width
        self.height = height
    }
    
    var body: some View {
        USDZSceneView(fileName: fileName)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onAppear {
                print(fileName)
            }
    }
}

// 内部実装（変更なし）
struct USDZSceneView: UIViewRepresentable {
    let fileName: String
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.allowsCameraControl = true
        scnView.backgroundColor = UIColor.systemBackground
        scnView.antialiasingMode = .multisampling2X
        
        let scene = SCNScene()
        scnView.scene = scene
        
        loadUSDZ(scene: scene, fileName: fileName)
        setupLighting(scene: scene)
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // ファイル名が変更された場合にシーンを更新
        guard let scene = uiView.scene else { return }
        
        // 既存のモデルを削除
        scene.rootNode.childNodes.forEach { $0.removeFromParentNode() }
        
        // 新しいモデルを読み込み
        loadUSDZ(scene: scene, fileName: fileName)
        setupLighting(scene: scene)
    }
    
    private func loadUSDZ(scene: SCNScene, fileName: String) {
        let cleanFileName = fileName.replacingOccurrences(of: ".usdz", with: "")
        
        guard let modelURL = Bundle.main.url(forResource: cleanFileName, withExtension: "usdz") else {
            print("USDZファイルが見つかりません: \(cleanFileName).usdz")
            createFallback(scene: scene)
            return
        }
        
        do {
            let modelScene = try SCNScene(url: modelURL)
            for child in modelScene.rootNode.childNodes {
                scene.rootNode.addChildNode(child)
            }
        } catch {
            print("読み込みエラー: \(error)")
            createFallback(scene: scene)
        }
    }
    
    private func createFallback(scene: SCNScene) {
        let box = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.1)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.systemBlue
        box.materials = [material]
        
        let boxNode = SCNNode(geometry: box)
        scene.rootNode.addChildNode(boxNode)
    }
    
    private func setupLighting(scene: SCNScene) {
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor.white
        ambientLight.intensity = 400
        
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)
        
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.color = UIColor.white
        directionalLight.intensity = 600
        
        let directionalNode = SCNNode()
        directionalNode.light = directionalLight
        directionalNode.position = SCNVector3(3, 3, 3)
        scene.rootNode.addChildNode(directionalNode)
    }
}
