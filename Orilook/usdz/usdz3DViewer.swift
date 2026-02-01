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
        
        // カメラ制御のカスタマイズ
//         バウンディングボックスではなく原点(0,0,0)を中心に回転させる
        scnView.defaultCameraController.automaticTarget = false
        scnView.defaultCameraController.target = SCNVector3(0, 0, 0)
//         ターンテーブルモード（Z軸回転をロックして水平回転しやすくする）
        scnView.defaultCameraController.interactionMode = .orbitTurntable
        // 慣性を有効化
        scnView.defaultCameraController.inertiaEnabled = true
        
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
            
            // モデルの内容物を一時的なラッパーノードに追加
            let wrapperNode = SCNNode()
            for child in modelScene.rootNode.childNodes {
                wrapperNode.addChildNode(child)
            }
            
            // バウンディングボックスを計算して重心を求める
            // scene.rootNodeに追加する前に計算する必要があるため、一時的にwrapperNodeを使う
            // (注: モデルが空の場合などは考慮が必要だが、基本的にはこれでOK)
            let (min, max) = wrapperNode.boundingBox
            let center = SCNVector3(
                x: (min.x + max.x) / 2,
                y: (min.y + max.y) / 2,
                z: (min.z + max.z) / 2
            )
            
            // 重心が原点(0,0,0)に来るようにラッパーノードをずらす
            wrapperNode.position = SCNVector3(-center.x, -center.y, -center.z)
            
            // さらにそのラッパーを格納する親ノード(これが(0,0,0)に配置される)を作成
            let rootAnchor = SCNNode()
            rootAnchor.addChildNode(wrapperNode)
            
            scene.rootNode.addChildNode(rootAnchor)
            
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
