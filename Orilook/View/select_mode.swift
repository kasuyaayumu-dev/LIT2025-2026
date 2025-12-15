import SwiftUI

struct select_mode: View {
    // 【重要】ここが 'let index: Int' ではなく、下記になっているか確認してください
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
        VStack {
            // 配列[index]ではなく、origamiを直接使用します
            Text(origami.name)
                .font(.system(size: 50))
            CustomImageView(origamiCode: origami.code)
                .scaledToFit()
            Text(languageManager.localizedString("select_mode"))
                .font(.system(size: 40))
            
            // 画面サイズ対応のモード選択ボタン
            GeometryReader { geometry in
                let buttonWidth = min(300, (geometry.size.width - 120) / 2)
                let spacing: CGFloat = 40
                
                VStack(spacing: spacing) {
                    HStack(spacing: spacing) {
                        if origami.fold {
                            Button(action: {
                                // データそのものを渡す
                                navigationManager.navigate(to: .descriptionFold(origami: origami))
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
                        
                        if origami.open {
                            Button(action: {
                                navigationManager.navigate(to: .descriptionOpen(origami: origami))
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
                        if origami.threed {
                            Button(action: {
                                navigationManager.navigate(to: .descriptionTheed(origami: origami))
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
                        
                        if origami.AR {
                            Button(action: {
                                navigationManager.navigate(to: .descriptionAR(origami: origami))
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
            .frame(height: 340)
            .tutorialTarget(id: "mode_buttons")
            .navigationTitle(languageManager.localizedString("select_mode_title"))
        }
        .toolbar {
            HStack {
                // お気に入りボタン
                Button(action: {
                    favoriteManager.toggleFavorite(origamiCode: origami.code)
                }) {
                    VStack{
                        Image(systemName: favoriteManager.isFavorite(origamiCode: origami.code) ? "heart.fill" : "heart")
                            .resizable()
                            .frame(width: 40,height: 40)
                            .foregroundColor(.red)
                    }
                }
                
                // カメラアイコン
                if completionManager.isCompleted(origamiCode: origami.code) {
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
                
                // 設定ボタン
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
            }
            .tutorialTarget(id: "toolbar_buttons")
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
}
