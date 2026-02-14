import SwiftUI

struct TutorialOverlay: View {
    @EnvironmentObject var tutorialManager: TutorialManager
    @EnvironmentObject var languageManager: LanguageManager
    let geometry: GeometryProxy
    let targetFrames: [String: CGRect]
    
    // 画面ごとのオフセット調整（必要な場合）
    private var frameYOffset: CGFloat {
        guard let flow = tutorialManager.currentFlow else { return -28 }
        switch flow {
        case .contentsList, .galleryView:
            return -28
        case .selectMode, .settings:
            return -128
        // 【修正】description3d を追加
        case .descriptionFold, .descriptionOpen, .descriptionAR, .description3d:
            return -128
        }
    }
    
    var body: some View {
        if tutorialManager.isActive, let step = tutorialManager.currentStep {
            ZStack {
                // 1. 背景マスク
                Color.black.opacity(0.7)
                    .mask(
                        ZStack {
                            Rectangle().fill(Color.white)
                            if let targetID = step.targetView, let rect = targetFrames[targetID] {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black)
                                    .frame(width: rect.width + 16, height: rect.height + 16)
                                    .position(x: rect.midX, y: rect.midY) // 座標空間を合わせているためoffset不要
                                    .blendMode(.destinationOut)
                            }
                        }
                        .compositingGroup()
                    )
                    .ignoresSafeArea()
                    .allowsHitTesting(true)
                
                // 2. ハイライト枠
                if let targetID = step.targetView, let rect = targetFrames[targetID] {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.themeIndigo, lineWidth: 4)
                        .frame(width: rect.width + 16, height: rect.height + 16)
                        .position(x: rect.midX, y: rect.midY)
                        .shadow(color: .themeIndigo.opacity(0.8), radius: 10)
                }
                
                // 3. 説明ダイアログ
                tutorialDialog(step: step)
            }
        }
    }
    
    private func tutorialDialog(step: TutorialStep) -> some View {
        VStack(spacing: 20) {
            Text(languageManager.localizedString(step.title))
                .font(.headline).fontWeight(.bold).multilineTextAlignment(.center)
            Text(languageManager.localizedString(step.message))
                .font(.body).multilineTextAlignment(.center)
            HStack {
                Button(action: { tutorialManager.skipTutorial() }) {
                    Text(languageManager.localizedString("tutorial_skip")).foregroundColor(.gray)
                }
                Spacer()
                Button(action: { tutorialManager.nextStep() }) {
                    Text(languageManager.localizedString("tutorial_next"))
                        .fontWeight(.bold).padding(.horizontal, 20).padding(.vertical, 10)
                        .background(Color.themeIndigo).foregroundColor(.white).cornerRadius(8)
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 10)
        .frame(width: 300)
        .position(calculateDialogPosition(step: step))
    }
    
    private func calculateDialogPosition(step: TutorialStep) -> CGPoint {
        let screenW = geometry.size.width
        let screenH = geometry.size.height
        guard let targetID = step.targetView, let rect = targetFrames[targetID] else {
            return CGPoint(x: screenW / 2, y: screenH / 2)
        }
        let offset: CGFloat = 160
        // ターゲット位置に応じて上下に配置
        return rect.midY > screenH / 2
            ? CGPoint(x: screenW / 2, y: rect.minY - offset)
            : CGPoint(x: screenW / 2, y: rect.maxY + offset)
    }
}
