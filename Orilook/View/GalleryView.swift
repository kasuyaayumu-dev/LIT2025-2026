import SwiftUI

struct GalleryView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var completionManager: CompletionManager
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var imageManager: ImageManager
    @EnvironmentObject var favoriteManager: FavoriteManager
    let origamiArray: [OrigamiController]
    @State private var selectedOrigami: OrigamiController?
    @State private var showingPhotoPickerSheet = false
    @State private var selectedImage: UIImage?
    
    // 3列のグリッドレイアウト
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // 左側：作品グリッド
                let twoColumns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
                LazyVGrid(columns: twoColumns, spacing: 8) {
                    ForEach(origamiArray) { origami in
                        galleryItemView(origami: origami)
                    }
                }
                .padding()
                .frame(width: geometry.size.width * 0.65)
                
                // 右側：選択した作品の詳細
                VStack {
                    if let selectedOrigami = selectedOrigami {
                        selectedDetailView(origami: selectedOrigami)
                    } else {
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
    
    private func galleryItemView(origami: OrigamiController) -> some View {
        let isSelected = selectedOrigami?.id == origami.id
        let isCompleted = completionManager.isCompleted(origamiCode: origami.code)
        let imageSize: CGFloat = 200
        
        return VStack(spacing: 6) {
            Button(action: {
                if selectedOrigami?.id == origami.id {
                    selectedOrigami = nil
                } else {
                    selectedOrigami = origami
                }
            }) {
                VStack(spacing: 6) {
                    ZStack {
                        CustomImageView(origamiCode: origami.code)
                            .scaledToFit()
                            .aspectRatio(1, contentMode: .fill)
                            .frame(width: imageSize, height: imageSize)
                            .clipped()
                            .grayscale(imageManager.hasUserImage(for: origami.code) ? 0.0 : 1.0)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                            )
                            .cornerRadius(12)
                            .animation(.easeInOut(duration: 0.3), value: isSelected)
                        
                        VStack {
                            HStack {
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
        return VStack(alignment: .center, spacing: 16) {
            CustomImageView(origamiCode: origami.code)
                .scaledToFit()
                .aspectRatio(1, contentMode: .fill)
                .frame(width: 200, height: 200)
                .clipped()
                .grayscale(imageManager.hasUserImage(for: origami.code) ? 0.0 : 1.0)
                .cornerRadius(16)
                .shadow(radius: 6)
            
            Text(origami.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
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
            
            VStack {
                Button(action: {
                    // 【重要】OrigamiControllerを直接渡す
                    navigationManager.navigate(to: .selectMode(origami: origami))
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
}
