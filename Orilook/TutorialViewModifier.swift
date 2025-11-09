import SwiftUI

struct TutorialViewModifier: ViewModifier {
    @EnvironmentObject var tutorialManager: TutorialManager
    let tutorialFlow: TutorialFlow
    let autoStart: Bool
    @State private var targetFrames: [String: CGRect] = [:]
    
    init(tutorialFlow: TutorialFlow, autoStart: Bool = true) {
        self.tutorialFlow = tutorialFlow
        self.autoStart = autoStart
    }
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            ZStack {
                // メインコンテンツ
                content
                    .onPreferenceChange(TutorialFramePreferenceKey.self) { frames in
                        self.targetFrames = frames
                    }
                    .onAppear {
                        if autoStart {
                            // 少し遅延を入れてレイアウト完了後にチュートリアルを開始
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                tutorialManager.startTutorial(for: tutorialFlow)
                            }
                        }
                    }
                
                // チュートリアルオーバーレイ（現在のフローと一致する場合のみ表示）
                if tutorialManager.currentFlow == tutorialFlow {
                    TutorialOverlay(geometry: geometry, targetFrames: targetFrames)
                }
            }
        }
    }
}

extension View {
    func tutorial(flow: TutorialFlow, autoStart: Bool = true) -> some View {
        self.modifier(TutorialViewModifier(tutorialFlow: flow, autoStart: autoStart))
    }
}