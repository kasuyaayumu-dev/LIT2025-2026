import SwiftUI

struct GalleryView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var completionManager: CompletionManager
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var imageManager: ImageManager
    @EnvironmentObject var favoriteManager: FavoriteManager
    
    let origamiArray: [OrigamiController]
    
    // 状態変数はこのビューで管理
    @State private var selectedOrigami: OrigamiController?
    @State private var showingPhotoPickerSheet = false
    @State private var selectedImage: UIImage?
    
    // アダプティブグリッド（幅に応じて列数が自動で変わります）
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 150, maximum: 250), spacing: 20)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // MARK: - 左側：作品一覧エリア (65%)
                ZStack {
                    Color.themeWashi.ignoresSafeArea()
                    
                    ScrollView {
                        // グリッド表示
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(origamiArray) { origami in
                                galleryItemView(origami: origami)
                            }
                        }
                        .padding(24)
                    }
                }
                .frame(width: geometry.size.width * 0.65)
                
                // 区切り線（影付き）
                Rectangle()
                    .fill(Color.black.opacity(0.1))
                    .frame(width: 1)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: -1, y: 0)
                
                // MARK: - 右側：詳細エリア (35%) - 床の間風
                ZStack {
                    Color.themeWashiDark.ignoresSafeArea()
                    
                    if let selectedOrigami = selectedOrigami {
                        ScrollView {
                            selectedDetailView(origami: selectedOrigami)
                                .padding(24)
                        }
                    } else {
                        // 未選択時
                        VStack(spacing: 20) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.5))
                            Text(languageManager.localizedString("gallery_select_item"))
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(width: geometry.size.width * 0.35)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedOrigami)
        .onChange(of: selectedImage) { image in
            if let image = image, let selectedOrigami = selectedOrigami {
                imageManager.saveUserImage(image, for: selectedOrigami.code)
            }
        }
        .sheet(isPresented: $showingPhotoPickerSheet) {
            PhotoPickerSheet(
                selectedImage: $selectedImage,
                isPresented: $showingPhotoPickerSheet
            )
        }
    }
    
    // MARK: - 一覧の各アイテム
    private func galleryItemView(origami: OrigamiController) -> some View {
        let isSelected = selectedOrigami?.id == origami.id
        let isCompleted = completionManager.isCompleted(origamiCode: origami.code)
        
        return Button(action: {
            selectedOrigami = origami
        }) {
            VStack(spacing: 0) {
                // 画像エリア
                ZStack(alignment: .topTrailing) {
                    // 修正箇所: .resizable() を削除しました
                    CustomImageView(origamiCode: origami.code)
                        .scaledToFill() // 枠いっぱいに埋める
                        .frame(minWidth: 0, maxWidth: .infinity) // 横幅いっぱい
                        .aspectRatio(1.0, contentMode: .fill) // 正方形に固定
                        .clipped() // はみ出した部分をカット
                        .grayscale(imageManager.hasUserImage(for: origami.code) ? 0.0 : 0.3)
                        .background(Color.white)
                    
                    // 選択枠
                    if isSelected {
                        Rectangle()
                            .strokeBorder(Color.themeIndigo, lineWidth: 4)
                    }
                    
                    // 完了スタンプ
                    if isCompleted {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.themeMatcha)
                            .font(.title3)
                            .background(Circle().fill(Color.white.opacity(0.9)))
                            .padding(6)
                    }
                }
                
                // テキスト情報
                HStack {
                    Text(origami.name)
                        .font(.system(size: 19))
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .themeIndigo : .themeSumi)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if favoriteManager.isFavorite(origamiCode: origami.code) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.themeVermilion)
                            .font(.caption)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.white : Color.white.opacity(0.8))
            }
            .cornerRadius(4)
            .shadow(color: Color.black.opacity(isSelected ? 0.2 : 0.1), radius: isSelected ? 6 : 2, y: isSelected ? 3 : 1)
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 詳細表示ビュー
    private func selectedDetailView(origami: OrigamiController) -> some View {
        VStack(spacing: 24) {
            // 写真（額装風）
            CustomImageView(origamiCode: origami.code)
                // 修正箇所: ここも .resizable() は不要（scaledToFitが効きます）
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 2, y: 4)
            
            // タイトル
            Text(origami.name)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.themeSumi)
            
            // 難易度
            HStack(spacing: 4) {
                if origami.dif == 0 {
                    Text(languageManager.localizedString("tutorial"))
                        .foregroundColor(.themeIndigo)
                } else {
                    ForEach(0..<5) { i in
                        Image(systemName: i < origami.dif ? "star.fill" : "star")
                            .foregroundColor(i < origami.dif ? .themeIndigo : .gray.opacity(0.3))
                            .font(.title3)
                    }
                }
            }
            
            // タグ
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                ForEach(origami.tag, id: \.self) { tag in
                    Text(languageManager.localizedString("genre_\(tag)"))
                        .font(.caption)
                        .padding(6)
                        .background(Color.themeIndigo.opacity(0.1))
                        .foregroundColor(.themeIndigo)
                        .cornerRadius(4)
                }
            }
            
            Divider().background(Color.themeSumi.opacity(0.2))
            
            // アクションボタン
            VStack(spacing: 12) {
                Button(action: { favoriteManager.toggleFavorite(origamiCode: origami.code) }) {
                    HStack {
                        Image(systemName: favoriteManager.isFavorite(origamiCode: origami.code) ? "heart.fill" : "heart")
                        Text(favoriteManager.isFavorite(origamiCode: origami.code) ?
                             languageManager.localizedString("remove_from_favorites") :
                             languageManager.localizedString("add_to_favorites"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(favoriteManager.isFavorite(origamiCode: origami.code) ? Color.themeVermilion : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                if completionManager.isCompleted(origamiCode: origami.code) {
                    Button(action: { showingPhotoPickerSheet = true }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text(languageManager.localizedString("change_photo"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.themeMatcha)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                
                Button(action: { navigationManager.navigate(to: .selectMode(origami: origami)) }) {
                    HStack {
                        Text(languageManager.localizedString("select_mode"))
                            .fontWeight(.bold)
                        Image(systemName: "chevron.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.themeIndigo)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .shadow(radius: 4)
                }
            }
        }
        .padding()
        .washiStyle()
    }
}
