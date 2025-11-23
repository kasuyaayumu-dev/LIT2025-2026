import SwiftUI
import ARKit
import RealityKit
import AVFoundation
import Combine

// AR状態管理クラス(シングルトン)
class ARStateManager: ObservableObject {
    static let shared = ARStateManager()
    
    @Published var modelStates: [String: ModelState] = [:]
    
    // ✅ UIからのリセット要求をCoordinatorに伝えるためのトリガー
    @Published var resetTrigger: UUID? = nil
    
    private(set) var savedWorldMap: ARWorldMap?
    private var currentSessionId: String?
    
    private init() {}
    
    struct ModelState {
        var isPlaced: Bool = false
        var placementTransform: simd_float4x4? // ✅ 修正: simd_float44 → simd_float4x4
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
    
    func setModelPlaced(fileName: String, at transform: simd_float4x4) { // ✅ 修正: simd_float44 → simd_float4x4
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
