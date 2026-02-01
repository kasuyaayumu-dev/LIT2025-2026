import SwiftUI

struct LangSet: View {
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        ZStack {
            // 背景：生成り色
            Color.themeWashi.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    
                    // 現在の言語タイトル（アニメーション付き）
                    Text(languageManager.localizedString("lang"))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.themeSumi)
                        .padding(.top)
                        .opacity(languageManager.isTransitioning ? 0.5 : 1.0)
                        .id(languageManager.language)
                        .transition(.opacity)
                    
                    // 言語選択リスト
                    VStack(spacing: 16) {
                        // 日本語
                        LanguageSelectionRow(
                            type: .japanese,
                            title: languageManager.localizedString("lang_jp"),
                            subtitle: "Japanese"
                        )
                        
                        // 英語
                        LanguageSelectionRow(
                            type: .english,
                            title: languageManager.localizedString("lang_en"),
                            subtitle: "English"
                        )
                    }
                    .padding(.horizontal, 24)
                    // 言語切り替え時のフェード
                    .opacity(languageManager.isTransitioning ? 0.6 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: languageManager.isTransitioning)
                    
                    // システム設定に戻すボタン
                    Button(action: {
                        languageManager.resetToSystemLanguage()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                            Text(languageManager.localizedString("reset_to_system_lang"))
                        }
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color.themeWashiDark)
                        .cornerRadius(20)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle(languageManager.localizedString("lang"))
        // 即座に反映させるためにLocaleを注入
        .environment(\.locale, languageManager.language.locale)
    }
    
    // 行コンポーネント
    private func LanguageSelectionRow(type: LanguageType, title: String, subtitle: String) -> some View {
        let isSelected = languageManager.language == type
        
        return Button(action: {
            // アニメーション付きで変更
            languageManager.changeLanguage(to: type, animationDuration: languageManager.setTransitionDuration(0.5))
        }) {
            HStack(spacing: 16) {
                // 左側に配置した和風ラジオボタン（FilterMenuと統一）
                WashiRadioButton(isSelected: isSelected)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .themeIndigo : .themeSumi)
                    
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(Color.white)
            // 共通の和紙スタイル（影など）
            .washiStyle()
            // 選択時は枠線を少し強調
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isSelected ? Color.themeIndigo.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // FilterMenuと共通のデザイン定義（朱色のラジオボタン）
    struct WashiRadioButton: View {
        let isSelected: Bool
        
        var body: some View {
            ZStack {
                // 外枠
                Circle()
                    .stroke(isSelected ? Color.themeVermilion : Color.gray.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 24, height: 24)
                
                // 選択時の塗りつぶし（印鑑風）
                if isSelected {
                    Circle()
                        .fill(Color.themeVermilion)
                        .frame(width: 14, height: 14)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LangSet()
            .environmentObject(LanguageManager())
    }
}
