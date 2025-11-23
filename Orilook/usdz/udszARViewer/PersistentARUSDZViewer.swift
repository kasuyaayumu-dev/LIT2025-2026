import SwiftUI
import ARKit
import RealityKit
import AVFoundation

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
                        EnhancedARControlsOverlay(fileName: fileName), // "fileName" は渡してもOK
                        alignment: .topTrailing
                    )
                    // .id(fileName) // ❌ この行を削除（ARViewを再生成させないため）
            } else {
                // ... (AR非対応時の代替表示) ...
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    // ...
            }
        }
    }
    
    private func isARSupported() -> Bool {
        return ARWorldTrackingConfiguration.isSupported
    }
}
