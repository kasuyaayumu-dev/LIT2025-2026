import SwiftUI

struct TutorialOverlay: View {
    @EnvironmentObject var tutorialManager: TutorialManager
    @EnvironmentObject var languageManager: LanguageManager
    let geometry: GeometryProxy
    let targetFrames: [String: CGRect] // 各ボタンの位置情報
    
    // 画面ごとの青い枠のオフセット調整
    private var frameYOffset: CGFloat {
        guard let flow = tutorialManager.currentFlow else { return -28 }
        switch flow {
        case .contentsList, .galleryView:
            return -28  // リストとギャラリーは28ポイント上
        case .selectMode, .settings:
            return -128  // モード選択と設定は128ポイント上
        }
    }
    
    var body: some View {
        if tutorialManager.isActive, let step = tutorialManager.currentStep {
            ZStack {
                // ターゲット要素のハイライト（穴あけ効果）
                if let targetView = step.targetView,
                   let targetFrame = targetFrames[targetView] {
                    
                    // 暗いオーバーレイと穴あけ効果
                    Canvas { context, size in
                        // 全体を暗くする
                        context.fill(
                            Path(CGRect(origin: .zero, size: size)),
                            with: .color(.black.opacity(0.7))
                        )
                        
                        // ハイライト部分を切り抜く
                        context.blendMode = .destinationOut
                        let highlightRect = CGRect(
                            x: targetFrame.minX - 10,
                            y: targetFrame.minY - 10, // 元の位置に戻す
                            width: targetFrame.width + 20,
                            height: targetFrame.height + 20
                        )
                        context.fill(
                            Path(roundedRect: highlightRect, cornerRadius: 12),
                            with: .color(.black)
                        )
                    }
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    
                    // ハイライト枠
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: targetFrame.width + 20, height: targetFrame.height + 20)
                        .position(x: targetFrame.midX, y: targetFrame.midY + frameYOffset) // 画面ごとに調整
                        .shadow(color: .blue.opacity(0.6), radius: 10)
                } else {
                    // ターゲットがない場合は全体を暗くする
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                }
                
                // チュートリアル説明ダイアログ
                tutorialDialog(step: step)
            }
        }
    }
    
    @ViewBuilder
    private func tutorialDialog(step: TutorialStep) -> some View {
        VStack(spacing: 20) {
            // タイトル
            Text(languageManager.localizedString(step.title))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // メッセージ
            Text(languageManager.localizedString(step.message))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            
            // ボタン群
            HStack(spacing: 16) {
                // スキップボタン
                Button(action: {
                    tutorialManager.skipTutorial()
                }) {
                    Text(languageManager.localizedString("tutorial_skip"))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
                
                // 次へボタン
                Button(action: {
                    tutorialManager.nextStep()
                }) {
                    HStack {
                        Text(isLastStep ? languageManager.localizedString("tutorial_done") : languageManager.localizedString("tutorial_next"))
                            .font(.body)
                            .fontWeight(.semibold)
                        
                        if !isLastStep {
                            Image(systemName: "arrow.right")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            }
            
            // ステップインジケーター
            if let flow = tutorialManager.currentFlow {
                HStack(spacing: 8) {
                    ForEach(0..<flow.steps.count, id: \.self) { index in
                        Circle()
                            .fill(index == tutorialManager.currentStepIndex ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 10)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(radius: 20)
        )
        .padding(.horizontal, 32)
        .position(dialogPosition(step: step))
        .id(step.id) // ステップごとに固有のIDを設定して再描画を防ぐ
    }
    
    private var isLastStep: Bool {
        guard let flow = tutorialManager.currentFlow else { return true }
        return tutorialManager.currentStepIndex >= flow.steps.count - 1
    }
    
    private func dialogPosition(step: TutorialStep) -> CGPoint {
        let screenWidth = geometry.size.width
        let screenHeight = geometry.size.height
        
        // ターゲット要素がある場合は、その位置に応じてダイアログ位置を調整
        if let targetView = step.targetView,
           let targetFrame = targetFrames[targetView] {
            
            switch step.position {
            case .topLeft:
                return CGPoint(
                    x: screenWidth * 0.3,
                    y: max(targetFrame.maxY + 100, screenHeight * 0.3)
                )
            case .topRight:
                return CGPoint(
                    x: screenWidth * 0.7,
                    y: max(targetFrame.maxY + 100, screenHeight * 0.3)
                )
            case .bottomLeft:
                return CGPoint(
                    x: screenWidth * 0.3,
                    y: min(targetFrame.minY - 100, screenHeight * 0.7)
                )
            case .bottomRight:
                return CGPoint(
                    x: screenWidth * 0.7,
                    y: min(targetFrame.minY - 100, screenHeight * 0.7)
                )
            case .top:
                return CGPoint(
                    x: screenWidth * 0.5,
                    y: max(targetFrame.maxY + 100, screenHeight * 0.3)
                )
            case .bottom:
                return CGPoint(
                    x: screenWidth * 0.5,
                    y: min(targetFrame.minY - 100, screenHeight * 0.7)
                )
            case .center:
                return CGPoint(x: screenWidth * 0.5, y: screenHeight * 0.5)
            }
        } else {
            // ターゲット要素がない場合は中央に表示
            return CGPoint(x: screenWidth * 0.5, y: screenHeight * 0.5)
        }
    }
}

// GeometryReaderでフレーム情報を取得するためのPreference Key
struct TutorialFramePreferenceKey: PreferenceKey {
    typealias Value = [String: CGRect]
    
    static var defaultValue: [String: CGRect] = [:]
    
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { (_, new) in new }
    }
}

// View拡張でフレーム情報を簡単に設定できるようにする
extension View {
    func tutorialTarget(id: String) -> some View {
        self
            .overlay(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: TutorialFramePreferenceKey.self,
                            value: [id: geometry.frame(in: .global)]
                        )
                }
            )
    }
}
