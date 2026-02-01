import SwiftUI

struct select_mode: View {
    let origami: OrigamiController
    
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var imageManager: ImageManager
    @EnvironmentObject var completionManager: CompletionManager
    @EnvironmentObject var favoriteManager: FavoriteManager
    @EnvironmentObject var tutorialManager: TutorialManager
    @State private var showingPhotoPickerSheet = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        ZStack {
            // 背景色
            Color.themeWashi.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // タイトル
                Text(origami.name)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.themeSumi)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                // 画像（額装風 + カメラボタン）
                ZStack(alignment: .bottomTrailing) {
                    CustomImageView(origamiCode: origami.code)
                        .scaledToFit()
                        .frame(maxWidth: 280)
                        .padding(12)
                        .background(Color.white)
                        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 2, y: 4)
                    
                    // 完了済みの場合、画像右下にカメラボタンを表示
                    if completionManager.isCompleted(origamiCode: origami.code) {
                        Button(action: { showingPhotoPickerSheet = true }) {
                            Image(systemName: "camera.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.themeIndigo)
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        .offset(x: 10, y: 10) // 少しはみ出させる
                    }
                }
                
                // サブタイトル
                Text(languageManager.localizedString("select_mode"))
                    .font(.title2)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                // ボタンレイアウト
                GeometryReader { geometry in
                    let buttonWidth = min(300, (geometry.size.width - 120) / 2)
                    let buttonHeight: CGFloat = 170
                    let spacing: CGFloat = 30
                    
                    VStack(spacing: spacing) {
                        HStack(spacing: spacing) {
                            if origami.fold {
                                ModeCardButton(
                                    title: languageManager.localizedString("fold"),
                                    icon: "doc.plaintext.fill",
                                    color: .themeIndigo,
                                    width: buttonWidth,
                                    height: buttonHeight,
                                    action: { navigationManager.navigate(to: .descriptionFold(origami: origami)) }
                                )
                            }
                            
                            if origami.open {
                                ModeCardButton(
                                    title: languageManager.localizedString("open"),
                                    icon: "map.fill",
                                    color: .themeVermilion,
                                    width: buttonWidth,
                                    height: buttonHeight,
                                    action: { navigationManager.navigate(to: .descriptionOpen(origami: origami)) }
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        HStack(spacing: spacing) {
                            if origami.threed {
                                ModeCardButton(
                                    title: languageManager.localizedString("3d"),
                                    icon: "cube.transparent.fill",
                                    color: .themeIndigo,
                                    width: buttonWidth,
                                    height: buttonHeight,
                                    action: { navigationManager.navigate(to: .descriptionTheed(origami: origami)) }
                                )
                            }
                            
                            if origami.AR {
                                ModeCardButton(
                                    title: languageManager.localizedString("AR"),
                                    icon: "camera.viewfinder",
                                    color: .themeVermilion,
                                    width: buttonWidth,
                                    height: buttonHeight,
                                    action: { navigationManager.navigate(to: .descriptionAR(origami: origami)) }
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                .frame(height: 380)
                .tutorialTarget(id: "mode_buttons")
            }
            .padding(.bottom, 20)
        }
        .navigationTitle(languageManager.localizedString("select_mode_title"))
        // ツールバー設定：ContentsListに合わせて個別のItemで配置
        .toolbar {
            // 左：お気に入り
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { favoriteManager.toggleFavorite(origamiCode: origami.code) }) {
                    Image(systemName: favoriteManager.isFavorite(origamiCode: origami.code) ? "heart.fill" : "heart")
                        .resizable().frame(width: 30, height: 30) // サイズ統一
                        .foregroundColor(favoriteManager.isFavorite(origamiCode: origami.code) ? .themeVermilion : .themeSumi)
                }
                .tutorialTarget(id: "favorite_button")
            }
            
            // 中：ヘルプ
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { tutorialManager.startTutorial(for: .selectMode, force: true) }) {
                    Image(systemName: "questionmark.circle")
                        .resizable().frame(width: 30, height: 30)
                        .foregroundColor(.themeIndigo)
                }
            }
            
            // 右：設定
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { navigationManager.navigate(to: .settings) }) {
                    Image(systemName: "gearshape.fill")
                        .resizable().frame(width: 30, height: 30)
                        .foregroundColor(.themeSumi)
                }
            }
        }
        .onChange(of: selectedImage) { image in
            if let image = image {
                imageManager.saveUserImage(image, for: origami.code)
            }
        }
        .sheet(isPresented: $showingPhotoPickerSheet) {
            PhotoPickerSheet(
                selectedImage: $selectedImage,
                isPresented: $showingPhotoPickerSheet
            )
        }
        .tutorial(flow: .selectMode, autoStart: true)
    }
    
    // MARK: - 和風カード型ボタンコンポーネント
    private func ModeCardButton(title: String, icon: String, color: Color, width: CGFloat, height: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.themeSumi)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: width, height: height)
            .background(Color.white)
            .washiStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
}
