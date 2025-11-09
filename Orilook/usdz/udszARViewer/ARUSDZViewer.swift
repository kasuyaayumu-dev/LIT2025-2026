import SwiftUI
import ARKit
import RealityKit
import AVFoundation

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
