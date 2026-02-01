import SwiftUI

struct settings: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var completionManager: CompletionManager
    @EnvironmentObject var imageManager: ImageManager
    @EnvironmentObject var favoriteManager: FavoriteManager
    @EnvironmentObject var tutorialManager: TutorialManager
    @EnvironmentObject var soundManager: SoundManager
    @State private var showResetAlert = false
    
    var body: some View {
        ZStack {
            // 背景：生成り色
            Color.themeWashi.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 言語設定
                    NavigationLink(destination: LangSet()) {
                        WashiSettingsRow(
                            icon: "globe",
                            title: languageManager.localizedString("lang"),
                            color: .themeIndigo
                        )
                    }
                    .tutorialTarget(id: "language_setting")
                    
                    // 音量とBGM設定
                    NavigationLink(destination: SoundSettings()) {
                        WashiSettingsRow(
                            icon: "speaker.wave.2",
                            title: languageManager.localizedString("sound_settings"),
                            color: .themeIndigo
                        )
                    }
                    .tutorialTarget(id: "sound_settings")
                    
                    // 進捗リセット（少し間を空けて配置）
                    Button(action: {
                        showResetAlert = true
                    }) {
                        WashiSettingsRow(
                            icon: "arrow.clockwise.circle",
                            title: languageManager.localizedString("progress_reset"),
                            subtitle: languageManager.localizedString("progress_reset_desc"),
                            color: .themeVermilion // 朱色で警告感
                        )
                    }
                    .padding(.top, 10)
                    .tutorialTarget(id: "progress_reset")
                    .alert(languageManager.localizedString("progress_reset_confirm_title"), isPresented: $showResetAlert) {
                        Button(languageManager.localizedString("cancel"), role: .cancel) {}
                        Button(languageManager.localizedString("reset"), role: .destructive) {
                            completionManager.resetAll()
                            imageManager.removeAllUserImages()
                            favoriteManager.resetAll()
                        }
                    } message: {
                        Text(languageManager.localizedString("progress_reset_confirm_message"))
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle(languageManager.localizedString("settings_title"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    tutorialManager.startTutorial(for: .settings, force: true)
                }) {
                    Image(systemName: "questionmark.circle")
                        .resizable()
                        .frame(width: 30, height: 30) // サイズ調整
                        .foregroundColor(.themeIndigo)
                }
            }
        }
        .tutorial(flow: .settings, autoStart: true)
    }
}

// MARK: - 設定画面用のカスタム行ビュー
struct WashiSettingsRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // アイコン背景
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.themeSumi)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.5))
                .font(.caption)
        }
        .padding(16)
        .washiStyle() // 共通の和紙カードスタイルを適用
    }
}

#Preview {
    NavigationStack {
        settings()
    }
    .environmentObject(LanguageManager())
    .environmentObject(CompletionManager())
    .environmentObject(ImageManager())
    .environmentObject(FavoriteManager())
    .environmentObject(TutorialManager())
    .environmentObject(SoundManager())
}
