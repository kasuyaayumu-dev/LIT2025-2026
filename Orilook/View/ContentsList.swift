import SwiftUI

struct ContentsList: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var filterManager: FilterManager
    @EnvironmentObject var viewModeManager: ViewModeManager
    @EnvironmentObject var completionManager: CompletionManager
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var imageManager: ImageManager
    @EnvironmentObject var favoriteManager: FavoriteManager
    @EnvironmentObject var tutorialManager: TutorialManager
    @EnvironmentObject var soundManager: SoundManager
    @State private var isTutorialPresented = false
    @State private var showingPhotoPickerSheet = false
    @State private var selectedImage: UIImage?
    @State private var selectedOrigamiCode: String?
    
    var body: some View {
        let origamiArray = getOrigamiArray(languageManager: languageManager)
        let filteredArray = filterManager.filterAndSortOrigami(origamiArray, languageManager: languageManager, favoriteManager: favoriteManager)
        NavigationStack(path: $navigationManager.path) {
            VStack(spacing: 0) {
                // コンテンツ表示
                if viewModeManager.selectedViewMode == .list {
                    listView(filteredArray: filteredArray, origamiArray: origamiArray)
                } else {
                    GalleryView(origamiArray: filteredArray)
                }
                
                // 下部メニューバーfolder.badge.questionmark
                bottomMenuBar()
            }
            .background(Color(.systemBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        tutorialManager.startTutorial(for: .contentsList, force: true)
                    }) {
                        Image(systemName: "questionmark.circle")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.blue)
                    }
                    .tutorialTarget(id: "help_button")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        filterManager.isFilterMenuPresented = true
                    }) {
                        ZStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(filterManager.hasActiveFilters ? .blue : .black)
                            
                            // フィルター適用時のインジケーター
                            if filterManager.hasActiveFilters {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 12, height: 12)
                                    .offset(x: 15, y: -15)
                            }
                        }
                    }
                    .tutorialTarget(id: "filter_button")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        navigationManager.navigate(to: .settings)
                    }) {
                        VStack {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.black)
                        }
                    }
                    .tutorialTarget(id: "settings_button")
                }
            }
            .sheet(isPresented: $filterManager.isFilterMenuPresented) {
                FilterMenu()
            }
            .sheet(isPresented: $isTutorialPresented) {
                SimpleTutorialView()
            }
            .navigationTitle(languageManager.localizedString("content_list_title"))
            .background(photoPickerAndOnChange)
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .selectMode(let index):
                    select_mode(index: index)
                case .descriptionFold(let index):
                    description_fold(index: index)
                case .descriptionOpen(let index):
                    description_open(index: index)
                case .descriptionTheed(let index):
                    description_theed(index: index)
                case .descriptionAR(let index):
                    description_AR(index: index)
                case .done(let index):
                    Done(index: index)
                case .settings:
                    settings()
                }
            }
        }
        .onAppear {
            // ContentsList表示時にBGMを開始
            soundManager.startBGMAfterLoading()
        }
        .tutorial(flow: .contentsList, autoStart: true)
    }
    
    private func listView(filteredArray: [OrigamiController], origamiArray: [OrigamiController]) -> some View {
        List {
            ForEach(
                0..<filteredArray.count,
                id: \.self
            ) { index in
                Button(action: {
                    //行き先 - 元のindexを渡す必要があるため、filteredArrayから元のindexを取得
                    let originalIndex = origamiArray.firstIndex { $0.id == filteredArray[index].id } ?? 0
                    navigationManager.navigate(to: .selectMode(index: originalIndex))
                }) {
                    HStack(spacing: 40) {
                        CustomImageView(origamiCode: filteredArray[index].code)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 400, height: 300)
                            .clipped()
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text(filteredArray[index].name)
                                    .font(.system(size: 40))
                                    .foregroundStyle(.black)
                                Spacer()
                                
                                // カメラボタン（完成済み作品の場合のみ）
                                if completionManager.isCompleted(origamiCode: filteredArray[index].code) {
                                    Button(action: {
                                        selectedOrigamiCode = filteredArray[index].code
                                        showingPhotoPickerSheet = true
                                    }) {
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.trailing, 8)
                                    
                                    // 完成バッジ
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title)
                                        .padding(.trailing, 8)
                                }
                                
                                // お気に入りボタン（一番右）
                                Button(action: {
                                    favoriteManager.toggleFavorite(origamiCode: filteredArray[index].code)
                                }) {
                                    Image(systemName: favoriteManager.isFavorite(origamiCode: filteredArray[index].code) ? "heart.fill" : "heart")
                                        .foregroundColor(.red)
                                        .font(.title2)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .tutorialTarget(id: "favorite_button")
                            }
                            HStack {
                                if filteredArray[index].dif == 0 {
                                    Text(languageManager.localizedString("tutorial"))
                                        .font(.body)
                                        .foregroundColor(.blue)
                                } else if filteredArray[index].dif <= 5 {
                                    ForEach((0..<filteredArray[index].dif), id: \.self) { num in
                                        Image(systemName: "star.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 40)
                                            .foregroundColor(.black)
                                    }
                                    ForEach((0..<5-filteredArray[index].dif), id: \.self) { num in
                                        Image(systemName: "star")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 40)
                                            .foregroundColor(.black)
                                    }
                                } else{
                                    ForEach((1...5), id: \.self) { num in
                                        Image(systemName: "star.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 40)
                                            .foregroundColor(.black)
                                    }
                                }
                            }
                            if filteredArray[index].dif > 5 {
                                HStack {
                                    ForEach((0..<filteredArray[index].dif-5), id: \.self) { num in
                                        Image(systemName: "star.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 40)
                                            .foregroundColor(.purple)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func bottomMenuBar() -> some View {
        HStack(spacing: 0) {
            // リストビューボタン
            HStack(spacing: 6) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 16))
                    .foregroundColor(viewModeManager.selectedViewMode == .list ? .blue : .gray)
                
                Text(languageManager.localizedString("list_view"))
                    .font(.caption)
                    .foregroundColor(viewModeManager.selectedViewMode == .list ? .blue : .gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(viewModeManager.selectedViewMode == .list ? Color.blue.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                viewModeManager.setViewMode(.list)
            }
            
            // 区切り線
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 0.5)
            
            // ギャラリービューボタン
            HStack(spacing: 6) {
                Image(systemName: "grid")
                    .font(.system(size: 16))
                    .foregroundColor(viewModeManager.selectedViewMode == .gallery ? .blue : .gray)
                
                Text(languageManager.localizedString("gallery_view"))
                    .font(.caption)
                    .foregroundColor(viewModeManager.selectedViewMode == .gallery ? .blue : .gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(viewModeManager.selectedViewMode == .gallery ? Color.blue.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                viewModeManager.setViewMode(.gallery)
            }
        }
        .frame(height: 50)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 0.5),
            alignment: .top
        )
        .tutorialTarget(id: "view_mode_bar")
    }
}

// ContentsList struct自体の最後に追加
extension ContentsList {
    private var photoPickerAndOnChange: some View {
        EmptyView()
            .onChange(of: selectedImage) { image in
                if let image = image, let origamiCode = selectedOrigamiCode {
                    imageManager.saveUserImage(image, for: origamiCode)
                    selectedOrigamiCode = nil
                }
            }
            .sheet(isPresented: $showingPhotoPickerSheet) {
                PhotoPickerSheet(
                    selectedImage: $selectedImage,
                    isPresented: $showingPhotoPickerSheet
                )
            }
    }
}
#Preview {
    CView()
        .environmentObject(LanguageManager())
        .environmentObject(FilterManager())
        .environmentObject(ViewModeManager())
        .environmentObject(CompletionManager())
        .environmentObject(NavigationManager())
        .environmentObject(ImageManager())
        .environmentObject(FavoriteManager())
        .environmentObject(TutorialManager())
        .environmentObject(SoundManager())
}
