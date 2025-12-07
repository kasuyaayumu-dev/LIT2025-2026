import SwiftUI

struct select_mode: View{
    let index: Int
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var imageManager: ImageManager
    @EnvironmentObject var completionManager: CompletionManager
    @EnvironmentObject var favoriteManager: FavoriteManager
    @EnvironmentObject var tutorialManager: TutorialManager
    @State private var showingPhotoPickerSheet = false
    @State private var selectedImage: UIImage?
    var body: some View {
        VStack{
            Text(getOrigamiArray(languageManager: languageManager)[index].name)
                .font(.system(size: 50))
            CustomImageView(origamiCode: getOrigamiArray(languageManager: languageManager)[index].code)
                .scaledToFit()
            Text(languageManager.localizedString("select_mode"))
                .font(.system(size: 40))
            // 画面サイズ対応のモード選択ボタン
            GeometryReader { geometry in
                let buttonWidth = min(300, (geometry.size.width - 120) / 2) // 最大300、最小は画面幅に合わせる
                let spacing: CGFloat = 40
                
                VStack(spacing: spacing) {
                    HStack(spacing: spacing) {
                        if getOrigamiArray(languageManager: languageManager)[index].fold == true {
                            Button(action: {
                                navigationManager.navigate(to: .descriptionFold(index: index))
                            }) {
                                Text(languageManager.localizedString("fold"))
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .frame(width: buttonWidth, height: 150)
                                    .background(.blue)
                                    .clipShape(.capsule)
                                    .shadow(color: Color.cyan, radius: 15, x: 0, y: 5)
                            }
                        }
                        
                        if getOrigamiArray(languageManager: languageManager)[index].open == true {
                            Button(action: {
                                navigationManager.navigate(to: .descriptionOpen(index: index))
                            }) {
                                Text(languageManager.localizedString("open"))
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .frame(width: buttonWidth, height: 150)
                                    .background(.blue)
                                    .clipShape(.capsule)
                                    .shadow(color: Color.cyan, radius: 15, x: 0, y: 5)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    HStack(spacing: spacing) {
                        if getOrigamiArray(languageManager: languageManager)[index].threed == true {
                            Button(action: {
                                navigationManager.navigate(to: .descriptionTheed(index: index))
                            }) {
                                Text(languageManager.localizedString("3d"))
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .frame(width: buttonWidth, height: 150)
                                    .background(.blue)
                                    .clipShape(.capsule)
                                    .shadow(color: Color.cyan, radius: 15, x: 0, y: 5)
                            }
                        }
                        
                        if getOrigamiArray(languageManager: languageManager)[index].AR == true {
                            Button(action: {
                                navigationManager.navigate(to: .descriptionAR(index: index))
                            }) {
                                Text(languageManager.localizedString("AR"))
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .frame(width: buttonWidth, height: 150)
                                    .background(.blue)
                                    .clipShape(.capsule)
                                    .shadow(color: Color.cyan, radius: 15, x: 0, y: 5)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 340) // 2行のボタン + スペーシングに必要な高さ
            .tutorialTarget(id: "mode_buttons")
            .navigationTitle(languageManager.localizedString("select_mode_title"))
        }
        .toolbar {
            HStack {
                // お気に入りボタン
                Button(action: {
                    favoriteManager.toggleFavorite(origamiCode: getOrigamiArray(languageManager: languageManager)[index].code)
                }) {
                    VStack{
                        Image(systemName: favoriteManager.isFavorite(origamiCode: getOrigamiArray(languageManager: languageManager)[index].code) ? "heart.fill" : "heart")
                            .resizable()
                            .frame(width: 40,height: 40)
                            .foregroundColor(.red)
                    }
                }
                
                // カメラアイコンボタン（完成済み作品の場合のみ表示）
                if completionManager.isCompleted(origamiCode: getOrigamiArray(languageManager: languageManager)[index].code) {
                    Button(action: {
                        showingPhotoPickerSheet = true
                    }) {
                        VStack{
                            Image(systemName: "camera.fill")
                                .resizable()
                                .frame(width: 40,height: 40)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // ヘルプボタン
                Button(action: {
                    tutorialManager.startTutorial(for: .selectMode, force: true)
                }) {
                    VStack{
                        Image(systemName: "questionmark.circle")
                            .resizable()
                            .frame(width: 40,height: 40)
                            .foregroundColor(.blue)
                    }
                }
                
                // 設定ギアアイコン
                Button(action: {
                    navigationManager.navigate(to: .settings)
                }) {
                    VStack{
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .frame(width: 40,height: 40)
                            .foregroundColor(.black)
                    }
                }
            }
            .tutorialTarget(id: "toolbar_buttons")
        }
        .onChange(of: selectedImage) { image in
            if let image = image {
                let origami = getOrigamiArray(languageManager: languageManager)[index]
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
}
