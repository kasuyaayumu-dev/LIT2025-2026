import SwiftUI

struct TutorialView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    private var tutorialPages: [TutorialPage] {
        [
            TutorialPage(
                iconName: "hand.wave.fill",
                titleKey: "tutorial_welcome_title",
                descriptionKey: "tutorial_welcome_desc",
                color: .blue
            ),
            TutorialPage(
                iconName: "star.fill",
                titleKey: "tutorial_difficulty_title", 
                descriptionKey: "tutorial_difficulty_desc",
                color: .orange
            ),
            TutorialPage(
                iconName: "line.3.horizontal.decrease.circle",
                titleKey: "tutorial_filter_title",
                descriptionKey: "tutorial_filter_desc",
                color: .green
            ),
            TutorialPage(
                iconName: "list.bullet",
                titleKey: "tutorial_viewmode_title",
                descriptionKey: "tutorial_viewmode_desc",
                color: .purple
            ),
            TutorialPage(
                iconName: "globe",
                titleKey: "tutorial_language_title",
                descriptionKey: "tutorial_language_desc",
                color: .cyan
            )
        ]
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // メインコンテンツエリア
                TabView(selection: $currentPage) {
                    ForEach(0..<tutorialPages.count, id: \.self) { index in
                        tutorialPageView(tutorialPages[index], index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // カスタムページインジケーター
                HStack(spacing: 8) {
                    ForEach(0..<tutorialPages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.primary : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                .padding(.vertical, 16)
                
                // ナビゲーションボタン
                HStack(spacing: 20) {
                    // 戻るボタン
                    Button(action: {
                        if currentPage > 0 {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                    }) {
                        Text(languageManager.localizedString("Back"))
                            .font(.headline)
                            .foregroundColor(currentPage > 0 ? .blue : .gray)
                            .frame(width: 100, height: 44)
                            .background(currentPage > 0 ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                            .cornerRadius(22)
                    }
                    .disabled(currentPage <= 0)
                    
                    Spacer()
                    
                    // 次へ/完了ボタン
                    Button(action: {
                        if currentPage < tutorialPages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            dismiss()
                        }
                    }) {
                        Text(currentPage < tutorialPages.count - 1 ? 
                             languageManager.localizedString("Forward") : 
                             languageManager.localizedString("tutorial_done"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 100, height: 44)
                            .background(currentPage < tutorialPages.count - 1 ? .green : .red)
                            .cornerRadius(22)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationTitle(languageManager.localizedString("tutorial_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(languageManager.localizedString("tutorial_skip")) {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func tutorialPageView(_ page: TutorialPage, index: Int) -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            // アイコン
            Image(systemName: page.iconName)
                .font(.system(size: 80))
                .foregroundColor(page.color)
                .scaleEffect(currentPage == index ? 1.0 : 0.8)
                .animation(.easeInOut, value: currentPage)
            
            // タイトル
            Text(languageManager.localizedString(page.titleKey))
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // 説明文
            Text(languageManager.localizedString(page.descriptionKey))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}

struct TutorialPage: Identifiable, Equatable {
    let id = UUID()
    let iconName: String
    let titleKey: String
    let descriptionKey: String
    let color: Color
    
    static func == (lhs: TutorialPage, rhs: TutorialPage) -> Bool {
        return lhs.id == rhs.id
    }
}

#Preview {
    TutorialView()
        .environmentObject(LanguageManager())
}