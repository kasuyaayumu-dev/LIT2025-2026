import SwiftUI

struct Done: View {
    let origami: OrigamiController
    
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var completionManager: CompletionManager
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var imageManager: ImageManager
    @EnvironmentObject var favoriteManager: FavoriteManager
    
    @State private var showingPhotoPickerSheet = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        ZStack {
            // 1. 背景：生成り色
            Color.themeWashi.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 40) {
                    // お祝いメッセージエリア
                    VStack(spacing: 16) {
                        Text(languageManager.localizedString("congratulations"))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.themeVermilion) // 朱色でお祝い
                            .multilineTextAlignment(.center)
                            .shadow(color: .themeVermilion.opacity(0.2), radius: 2, x: 0, y: 2)
                        
                        Text(origami.name)
                            .font(.title)
                            .fontWeight(.medium)
                            .foregroundColor(.themeSumi)
                    }
                    .padding(.top, 40)
                    
                    // 2. 完成作品の画像（額装風）
                    ZStack {
                        Color.white
                        
                        CustomImageView(origamiCode: origami.code)
                            .scaledToFit()
                            .padding(24) // 余白を広めにとって「余白の美」を表現
                    }
                    .frame(maxWidth: 700) // 程よいサイズ感に
                    .cornerRadius(8)
                    .washiStyle() // 和紙風の影とスタイル
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
                    // 完了スタンプのような装飾
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.themeMatcha)
                            .background(Circle().fill(Color.white))
                            .offset(x: 10, y: 10)
                            .shadow(radius: 4)
                    }
                    
                    // 3. アクションボタン群
                    VStack(spacing: 20) {
                        // 写真を撮るボタン
                        Button(action: {
                            showingPhotoPickerSheet = true
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text(languageManager.localizedString("pic_select"))
                                    .fontWeight(.bold)
                            }
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.themeIndigo) // 藍色
                            .cornerRadius(12)
                            .shadow(color: .themeIndigo.opacity(0.3), radius: 4, y: 2)
                        }
                        
                        // リストに戻るボタン
                        Button(action: {
                            // ナビゲーションスタックをリセットして戻る
                            navigationManager.popToRoot()
                        }) {
                            HStack {
                                Image(systemName: "list.bullet")
                                Text(languageManager.localizedString("back_to_list"))
                                    .fontWeight(.bold)
                            }
                            .font(.title3)
                            .foregroundColor(.themeSumi) // 文字は墨色
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white) // 背景は白
                            .cornerRadius(12)
                            .washiStyle() // 和紙風スタイル
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.themeSumi.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true) // 完了画面なので「戻る」ボタンは消す
        .onAppear {
            // 画面表示時に完了フラグを立てる
            completionManager.markAsCompleted(origamiCode: origami.code)
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { favoriteManager.toggleFavorite(origamiCode: origami.code) }) {
                    Image(systemName: favoriteManager.isFavorite(origamiCode: origami.code) ? "heart.fill" : "heart")
                        .resizable().frame(width: 30, height: 30)
                        .foregroundColor(favoriteManager.isFavorite(origamiCode: origami.code) ? .themeVermilion : .themeSumi)
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
    }
}
