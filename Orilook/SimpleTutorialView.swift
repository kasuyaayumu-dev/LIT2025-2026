import SwiftUI

struct SimpleTutorialView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    private let pages = [
        ("hand.wave.fill", "tutorial_welcome_title", "tutorial_welcome_desc"),
        ("star.fill", "tutorial_difficulty_title", "tutorial_difficulty_desc"),
        ("line.3.horizontal.decrease.circle", "tutorial_filter_title", "tutorial_filter_desc"),
        ("list.bullet", "tutorial_viewmode_title", "tutorial_viewmode_desc"),
        ("globe", "tutorial_language_title", "tutorial_language_desc")
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 32) {
                            Spacer()
                            
                            Image(systemName: pages[index].0)
                                .font(.system(size: 80))
                                .foregroundColor(.blue)
                            
                            Text(languageManager.localizedString(pages[index].1))
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(languageManager.localizedString(pages[index].2))
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            
                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.primary : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.vertical, 16)
                
                HStack(spacing: 20) {
                    Button(languageManager.localizedString("Back")) {
                        if currentPage > 0 {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                    }
                    .disabled(currentPage <= 0)
                    
                    Spacer()
                    
                    Button(currentPage < pages.count - 1 ? 
                           languageManager.localizedString("Forward") : 
                           languageManager.localizedString("tutorial_done")) {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            dismiss()
                        }
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
                }
            }
        }
    }
}

#Preview {
    SimpleTutorialView()
        .environmentObject(LanguageManager())
}