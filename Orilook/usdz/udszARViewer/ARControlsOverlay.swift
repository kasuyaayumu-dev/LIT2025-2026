import SwiftUI
import ARKit
import RealityKit
import AVFoundation

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
