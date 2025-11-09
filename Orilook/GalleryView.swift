import SwiftUI

// 表示アイテムの種類
enum DisplayItemType {
    case origami(OrigamiController, Int)
    case detail(OrigamiController)
    case spacer
}

// 表示アイテム
struct DisplayItem: Identifiable {
    let id = UUID()
    let type: DisplayItemType
}

struct GalleryView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var completionManager: CompletionManager
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var imageManager: ImageManager
    @EnvironmentObject var favoriteManager: FavoriteManager
    let origamiArray: [OrigamiController]
    @State private var selectedOrigami: OrigamiController?
    @State private var selectedIndex: Int?
    @State private var showingPhotoPickerSheet = false
    @State private var selectedImage: UIImage?
    
    // 3列のグリッドレイアウト
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // 左側：作品グリッド（画面の約2/3を使用）
                let twoColumns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
                LazyVGrid(columns: twoColumns, spacing: 8) {
                    ForEach(Array(origamiArray.enumerated()), id: \.offset) { index, origami in
                        galleryItemView(origami: origami, index: index)
                    }
                }
                .padding()
                .frame(width: geometry.size.width * 0.65)
                
                // 右側：選択した作品の詳細（画面の約1/3を使用）
                VStack {
                    if let selectedOrigami = selectedOrigami {
                        selectedDetailView(origami: selectedOrigami)
                    } else {
                        // 何も選択されていない場合のプレースホルダー
                        VStack {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text(languageManager.localizedString("gallery_select_item"))
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .frame(width: geometry.size.width * 0.35)
                .frame(maxHeight: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedOrigami)
        .background(Color(.systemGroupedBackground))
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
    
    private func galleryItemView(origami: OrigamiController, index: Int) -> some View {
        let isSelected = selectedOrigami?.code == origami.code
        let isCompleted = completionManager.isCompleted(origamiCode: origami.code)
        let imageSize: CGFloat = 200 // 左側が大きくなったので画像も大きく
        
        return VStack(spacing: 6) {
            Button(action: {
                if selectedOrigami?.code == origami.code {
                    selectedOrigami = nil // 同じ画像をタップしたら閉じる
                    selectedIndex = nil
                } else {
                    selectedOrigami = origami
                    selectedIndex = index
                }
            }) {
                VStack(spacing: 6) {
                    ZStack {
                        // 画像（ユーザー画像がある場合はそれを使用、ない場合はモノクロ）
                        CustomImageView(origamiCode: origami.code)
                            .scaledToFit()
                            .aspectRatio(1, contentMode: .fill)
                            .frame(width: imageSize, height: imageSize)
                            .clipped()
                            .grayscale(imageManager.hasUserImage(for: origami.code) ? 0.0 : 1.0) // ユーザー画像がある場合はカラー、ない場合はモノクロ
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                            )
                            .cornerRadius(12)
                            .animation(.easeInOut(duration: 0.3), value: isSelected)
                        
                        // お気に入りボタンと完成バッジ
                        VStack {
                            HStack {
                                // お気に入りボタン（左上）
                                Button(action: {
                                    favoriteManager.toggleFavorite(origamiCode: origami.code)
                                }) {
                                    Image(systemName: favoriteManager.isFavorite(origamiCode: origami.code) ? "heart.fill" : "heart")
                                        .foregroundColor(.red)
                                        .font(.title3)
                                        .background(Circle().fill(Color.white).shadow(radius: 2))
                                        .padding(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Spacer()
                                
                                // 完成バッジ（右上）
                                if isCompleted {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title2)
                                        .background(Circle().fill(Color.white))
                                        .padding(8)
                                }
                            }
                            Spacer()
                        }
                    }
                    
                    // 名前
                    Text(origami.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(height: 32)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func selectedDetailView(origami: OrigamiController) -> some View {
        // フィルターされた配列から元の配列のインデックスを取得
        let fullOrigamiArray = getOrigamiArray(languageManager: languageManager)
        let originalIndex = fullOrigamiArray.firstIndex { $0.code == origami.code } ?? 0
        
        return VStack(alignment: .center, spacing: 16) {
            // 選択された作品の大きめ画像
            CustomImageView(origamiCode: origami.code)
                .scaledToFit()
                .aspectRatio(1, contentMode: .fill)
                .frame(width: 200, height: 200)
                .clipped()
                .grayscale(imageManager.hasUserImage(for: origami.code) ? 0.0 : 1.0)
                .cornerRadius(16)
                .shadow(radius: 6)
            
            // 作品名
            Text(origami.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // 難易度表示
            VStack(spacing: 8) {
                Text(languageManager.localizedString("difficulty"))
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .fontWeight(.semibold)
                
                if origami.dif == 0 {
                    Text(languageManager.localizedString("tutorial"))
                        .font(.title3)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                } else {
                    HStack(spacing: 4) {
                        ForEach(0..<min(origami.dif, 5), id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .foregroundColor(.black)
                                .font(.system(size: 20))
                        }
                        if origami.dif > 5 {
                            ForEach(0..<(origami.dif - 5), id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .foregroundColor(.purple)
                                    .font(.system(size: 20))
                            }
                        }
                    }
                }
            }
            
            // ジャンルタグ
            VStack(spacing: 8) {
                Text(languageManager.localizedString("genre"))
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .fontWeight(.semibold)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(origami.tag, id: \.self) { tag in
                        Text(languageManager.localizedString("genre_\(tag)"))
                            .font(.body)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                }
            }
            
            // お気に入りボタン
            Button(action: {
                favoriteManager.toggleFavorite(origamiCode: origami.code)
            }) {
                HStack {
                    Image(systemName: favoriteManager.isFavorite(origamiCode: origami.code) ? "heart.fill" : "heart")
                        .font(.title2)
                    Text(favoriteManager.isFavorite(origamiCode: origami.code) ? 
                         languageManager.localizedString("remove_from_favorites") : 
                         languageManager.localizedString("add_to_favorites"))
                        .font(.title3)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.body)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.red)
                .cornerRadius(12)
            }
            .padding(.bottom, 10)
            
            // カメラボタン（完成済み作品の場合のみ）
            if completionManager.isCompleted(origamiCode: origami.code) {
                Button(action: {
                    showingPhotoPickerSheet = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                        Text(languageManager.localizedString("change_photo"))
                            .font(.title3)
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.body)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .cornerRadius(12)
                }
                .padding(.bottom, 10)
            }
            
            Spacer()
            
            // モード選択ボタン（画面サイズ対応の中央寄せ）
            VStack {
                Button(action: {
                    navigationManager.navigate(to: .selectMode(index: originalIndex))
                }) {
                    HStack {
                        Spacer(minLength: 0)
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                        Text(languageManager.localizedString("select_mode"))
                            .font(.title3)
                            .fontWeight(.semibold)
                        Spacer(minLength: 0)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
    }
    
    private func detailPanel(origami: OrigamiController) -> some View {
        // フィルターされた配列から元の配列のインデックスを取得
        let fullOrigamiArray = getOrigamiArray(languageManager: languageManager)
        let originalIndex = fullOrigamiArray.firstIndex { $0.code == origami.code } ?? 0
        
        return VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            HStack {
                Text(languageManager.localizedString("gallery_details"))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    selectedOrigami = nil
                    selectedIndex = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // 作品情報
            VStack(alignment: .leading, spacing: 16) {
                // 難易度表示
                VStack(alignment: .leading, spacing: 8) {
                    Text(languageManager.localizedString("difficulty"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fontWeight(.semibold)
                    
                    if origami.dif == 0 {
                        Text(languageManager.localizedString("tutorial"))
                            .font(.body)
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    } else {
                        HStack(spacing: 4) {
                            ForEach(0..<min(origami.dif, 5), id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .foregroundColor(.black)
                                    .font(.system(size: 18))
                            }
                            if origami.dif > 5 {
                                ForEach(0..<(origami.dif - 5), id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.purple)
                                        .font(.system(size: 18))
                                }
                            }
                        }
                    }
                }
                
                // ジャンルタグ
                VStack(alignment: .leading, spacing: 8) {
                    Text(languageManager.localizedString("genre"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(origami.tag, id: \.self) { tag in
                            Text(languageManager.localizedString("genre_\(tag)"))
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                }
                
                // モード選択ボタン（画面サイズ対応の中央寄せ）
                VStack {
                    NavigationLink(destination: select_mode(index: originalIndex)) {
                        HStack {
                            Spacer(minLength: 0)
                            Image(systemName: "play.circle.fill")
                                .font(.title3)
                            Text(languageManager.localizedString("select_mode"))
                                .font(.body)
                                .fontWeight(.semibold)
                            Spacer(minLength: 0)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
.frame(minHeight: 200, maxHeight: 200)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
    
}
