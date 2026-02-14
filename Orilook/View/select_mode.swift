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
                        .frame(maxWidth: 700)
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
                        .offset(x: 10, y: 10)
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
                    let spacing: CGFloat = 40
                    
                    VStack(spacing: spacing) {
                        // 1行目: Fold & Open
                        HStack(spacing: spacing) {
                            ModeCardButton(
                                title: languageManager.localizedString("fold"),
                                icon: "doc.plaintext.fill",
                                color: .themeIndigo,
                                isEnabled: origami.fold, // 有効/無効判定
                                width: buttonWidth,
                                height: buttonHeight,
                                action: { navigationManager.navigate(to: .descriptionFold(origami: origami)) }
                            )
                            
                            ModeCardButton(
                                title: languageManager.localizedString("open"),
                                icon: "map.fill",
                                color: .themeVermilion,
                                isEnabled: origami.open,
                                width: buttonWidth,
                                height: buttonHeight,
                                action: { navigationManager.navigate(to: .descriptionOpen(origami: origami)) }
                            )
                        }
                        .frame(maxWidth: .infinity)
                        
                        // 2行目: 3D & AR
                        HStack(spacing: spacing) {
                            ModeCardButton(
                                title: languageManager.localizedString("3d"),
                                icon: "cube.transparent.fill",
                                color: .themeIndigo,
                                isEnabled: origami.threed,
                                width: buttonWidth,
                                height: buttonHeight,
                                action: { navigationManager.navigate(to: .descriptionTheed(origami: origami)) }
                            )
                            
                            ModeCardButton(
                                title: languageManager.localizedString("AR"),
                                icon: "camera.viewfinder",
                                color: .themeVermilion,
                                isEnabled: origami.AR,
                                width: buttonWidth,
                                height: buttonHeight,
                                action: { navigationManager.navigate(to: .descriptionAR(origami: origami)) }
                            )
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
        // ツールバー
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { favoriteManager.toggleFavorite(origamiCode: origami.code) }) {
                    Image(systemName: favoriteManager.isFavorite(origamiCode: origami.code) ? "heart.fill" : "heart")
                        .resizable().frame(width: 30, height: 30)
                        .foregroundColor(favoriteManager.isFavorite(origamiCode: origami.code) ? .themeVermilion : .themeSumi)
                }
                .tutorialTarget(id: "favorite_button")
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { tutorialManager.startTutorial(for: .selectMode, force: true) }) {
                    Image(systemName: "questionmark.circle")
                        .resizable().frame(width: 30, height: 30)
                        .foregroundColor(.themeIndigo)
                }
            }
            
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
    
    // MARK: - 和風カード型ボタンコンポーネント（無効状態対応）
    private func ModeCardButton(
        title: String,
        icon: String,
        color: Color,
        isEnabled: Bool, // パラメータ追加
        width: CGFloat,
        height: CGFloat,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        // 無効時はグレー、有効時は指定色の薄い背景
                        .fill(isEnabled ? color.opacity(0.1) : Color.gray.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        // 無効時はグレー、有効時は指定色
                        .foregroundColor(isEnabled ? color : .gray)
                }
                
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    // 無効時はグレー、有効時は墨色
                    .foregroundColor(isEnabled ? .themeSumi : .gray)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: width, height: height)
            // 無効時は背景を少し暗くするか、白のまま不透明度を下げる
            .background(Color.white)
            .opacity(isEnabled ? 1.0 : 0.5) // 全体を半透明に
            .washiStyle() // 共通スタイル（影など）
        }
        .disabled(!isEnabled) // ボタン操作を無効化
        .buttonStyle(PlainButtonStyle())
    }
}
