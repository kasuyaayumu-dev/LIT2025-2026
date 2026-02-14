import SwiftUI

struct TutorialViewModifier: ViewModifier {
    @EnvironmentObject var tutorialManager: TutorialManager
    let tutorialFlow: TutorialFlow
    let autoStart: Bool
    @State private var targetFrames: [String: CGRect] = [:]
    
    func body(content: Content) -> some View {
        ZStack {
            // メインコンテンツ
            content
                .onPreferenceChange(TutorialFramePreferenceKey.self) { frames in
                    self.targetFrames = frames
                }
                .onAppear {
                    if autoStart {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            tutorialManager.startTutorial(for: tutorialFlow)
                        }
                    }
                }
            
            // チュートリアルオーバーレイ
            if tutorialManager.currentFlow == tutorialFlow {
                // GeometryReaderを使って画面サイズを渡す
                GeometryReader { geometry in
                    TutorialOverlay(geometry: geometry, targetFrames: targetFrames)
                }
            }
        }
    }
}

// ターゲットの位置情報を収集するためのPreference Key
struct TutorialFramePreferenceKey: PreferenceKey {
    typealias Value = [String: CGRect]
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { (_, new) in new }
    }
}

// View拡張
extension View {
    // 画面全体にチュートリアル機能を付与する
    func tutorial(flow: TutorialFlow, autoStart: Bool = true) -> some View {
        self.modifier(TutorialViewModifier(tutorialFlow: flow, autoStart: autoStart))
    }
    
    // チュートリアルのターゲットとなる要素に付ける
    func tutorialTarget(id: String) -> some View {
        self.background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: TutorialFramePreferenceKey.self,
                    // 【重要】ここで共通の座標空間 "tutorialSpace" を指定してズレを防ぐ
                    value: [id: geometry.frame(in: .named("tutorialSpace"))]
                )
            }
        )
    }
}
