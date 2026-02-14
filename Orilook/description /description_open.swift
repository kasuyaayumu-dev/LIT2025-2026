import SwiftUI

struct description_open: View {
    let origami: OrigamiController
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var favoriteManager: FavoriteManager
    @EnvironmentObject var tutorialManager: TutorialManager
    
    var body: some View {
        ZStack {
            // 背景：生成り色
            Color.themeWashi.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // ヘッダー
                    VStack(spacing: 8) {
                        Text(origami.name)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.themeSumi)
                        
                        Text(languageManager.localizedString("open"))
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 10)
                    
                    // 展開図（額装風）
                    VStack(spacing: 16) {
                        Image(origami.code + "_open")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .padding(20)
                            .background(Color.white)
                            .overlay(
                                Rectangle()
                                    .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        Text(origami.name + languageManager.localizedString("opens"))
                            .font(.subheadline)
                            .foregroundColor(.themeSumi)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    
                    // 完了ボタン
                    Button(action: {
                        navigationManager.navigate(to: .done(origami: origami))
                    }) {
                        HStack {
                            Text(languageManager.localizedString("Done"))
                            Image(systemName: "checkmark.seal.fill")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.themeVermilion)
                        .cornerRadius(12)
                        .shadow(color: Color.themeVermilion.opacity(0.3), radius: 4, y: 2)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { favoriteManager.toggleFavorite(origamiCode: origami.code) }) {
                    Image(systemName: favoriteManager.isFavorite(origamiCode: origami.code) ? "heart.fill" : "heart")
                        .resizable().frame(width: 30, height: 30)
                        .foregroundColor(favoriteManager.isFavorite(origamiCode: origami.code) ? .themeVermilion : .themeSumi)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { tutorialManager.startTutorial(for: .descriptionOpen, force: true) }) {
                    Image(systemName: "questionmark.circle")
                        .resizable().frame(width: 30, height: 30)
                        .foregroundColor(.themeIndigo)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    navigationManager.navigate(to: .settings)
                }) {
                    Image(systemName: "gearshape.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.themeSumi)
                }
            }
        }
        .tutorial(flow: .descriptionOpen, autoStart: true)
    }
}
