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
        List {
                // 言語設定
                NavigationLink(destination: LangSet()) {
                    HStack {
                        Image(systemName: "globe")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text(languageManager.localizedString("lang"))
                    }
                }
                .tutorialTarget(id: "language_setting")
                
                // 音量とBGM設定
                NavigationLink(destination: SoundSettings()) {
                    HStack {
                        Image(systemName: "speaker.wave.2")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.blue)
                        Text(languageManager.localizedString("sound_settings"))
                    }
                }
                .tutorialTarget(id: "sound_settings")
                
                // 進捗リセット
                Button(action: {
                    showResetAlert = true
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(languageManager.localizedString("progress_reset"))
                                .foregroundColor(.primary)
                            Text(languageManager.localizedString("progress_reset_desc"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
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
        .navigationTitle(languageManager.localizedString("settings_title"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    tutorialManager.startTutorial(for: .settings, force: true)
                }) {
                    Image(systemName: "questionmark.circle")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.blue)
                }
            }
        }
        .tutorial(flow: .settings, autoStart: true)
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
