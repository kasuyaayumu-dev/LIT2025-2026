import SwiftUI

struct LangSet: View {
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text(languageManager.localizedString("lang"))
                .font(.title)
                .padding(.top)
                .opacity(languageManager.isTransitioning ? 0.5 : 1.0)
                .id(languageManager.language)
                .frame(maxWidth: .infinity)
                .transition(.opacity)
            
            List {
                // 日本語選択
                HStack {
                    Text(languageManager.localizedString("lang_jp"))
                        .font(.body)
                    Spacer()
                    if languageManager.language == .japanese {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    languageManager.changeLanguage(to: .japanese, animationDuration: languageManager.setTransitionDuration(0.5))
                }
                .foregroundColor(languageManager.language == .japanese ? .blue : .primary)
                .opacity(languageManager.isTransitioning ? 0.5 : 1.0)
                
                // 英語選択
                HStack {
                    Text(languageManager.localizedString("lang_en"))
                        .font(.body)
                    Spacer()
                    if languageManager.language == .english {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    languageManager.changeLanguage(to: .english, animationDuration: languageManager.setTransitionDuration(0.5))
                }
                .foregroundColor(languageManager.language == .english ? .blue : .primary)
                .opacity(languageManager.isTransitioning ? 0.5 : 1.0)
            }
            
            // システム言語に戻すボタン（オプション）
            Button(action: {
                languageManager.resetToSystemLanguage()
            }) {
                Text(languageManager.localizedString("reset_to_system_lang"))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom)
        }
        .environment(\.locale, languageManager.language.locale)
    }
}

#Preview {
    LangSet()
        .environmentObject(LanguageManager())
}
