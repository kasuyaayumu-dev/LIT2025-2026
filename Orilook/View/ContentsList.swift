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
        let origamiArray = getAllOrigamiArray(languageManager: languageManager)
        let filteredArray = filterManager.filterAndSortOrigami(origamiArray, languageManager: languageManager, favoriteManager: favoriteManager)
        
        NavigationStack(path: $navigationManager.path) {
            VStack(spacing: 0) {
                // コンテンツ表示エリア
                ZStack {
                    // 背景：生成り色
                    Color.themeWashi.ignoresSafeArea()
                    
                    if viewModeManager.selectedViewMode == .list {
                        // 和風リスト（ScrollView）
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                ForEach(filteredArray) { origami in
                                    WashiListItem(origami: origami)
                                        .padding(.horizontal, 24)
                                }
                            }
                            .padding(.vertical, 20)
                        }
                    } else {
                        // 和風ギャラリー（Split View）
                        GalleryView(origamiArray: filteredArray)
                    }
                }
                
                // 下部メニューバー
                bottomMenuBar()
            }
            // --- 以下、既存のツールバーや設定 ---
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { filterManager.isFilterMenuPresented = true }) {
                        ZStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .resizable().frame(width: 30, height: 30)
                                .foregroundColor(filterManager.hasActiveFilters ? .themeIndigo : .themeSumi)
                            if filterManager.hasActiveFilters {
                                Circle().fill(Color.themeVermilion).frame(width: 10, height: 10).offset(x: 10, y: -10)
                            }
                        }
                    }
                    .tutorialTarget(id: "filter_button")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { tutorialManager.startTutorial(for: .contentsList, force: true) }) {
                        Image(systemName: "questionmark.circle")
                            .resizable().frame(width: 30, height: 30)
                            .foregroundColor(.themeIndigo)
                    }
                    .tutorialTarget(id: "help_button")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { navigationManager.navigate(to: .settings) }) {
                        Image(systemName: "gearshape.fill")
                            .resizable().frame(width: 30, height: 30)
                            .foregroundColor(.themeSumi)
                    }
                    .tutorialTarget(id: "settings_button")
                }
            }
            .sheet(isPresented: $filterManager.isFilterMenuPresented) { FilterMenu() }
            .sheet(isPresented: $isTutorialPresented) { SimpleTutorialView() }
            .navigationTitle(languageManager.localizedString("content_list_title"))
            .background(photoPickerAndOnChange)
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .selectMode(let origami): select_mode(origami: origami)
                case .descriptionFold(let origami): description_fold(origami: origami)
                case .descriptionOpen(let origami): description_open(origami: origami)
                case .descriptionTheed(let origami): DescriptionThreed(origami: origami)
                case .descriptionAR(let origami): description_AR(origami: origami)
                case .done(let origami): Done(origami: origami)
                case .settings: settings()
                }
            }
        }
        .onAppear { soundManager.startBGMAfterLoading() }
        .tutorial(flow: .contentsList, autoStart: true)
    }
    
    // 木札・短冊風リストアイテム
    private func WashiListItem(origami: OrigamiController) -> some View {
        Button(action: {
            navigationManager.navigate(to: .selectMode(origami: origami))
        }) {
            HStack(spacing: 20) {
                // サムネイル
                CustomImageView(origamiCode: origami.code)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 130)
                    .clipped()
                    .cornerRadius(4)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                
                VStack(alignment: .leading, spacing: 10) {
                    // タイトルと完了マーク
                    HStack {
                        Text(origami.name)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.themeSumi)
                        
                        Spacer()
                        
                        if completionManager.isCompleted(origamiCode: origami.code) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.themeMatcha)
                                .font(.title)
                        }
                    }
                    
                    // 難易度とお気に入り
                    HStack {
                        if origami.dif == 0 {
                            Text(languageManager.localizedString("tutorial"))
                                .font(.body)
                                .foregroundColor(.themeIndigo)
                        } else {
                            HStack(spacing: 2) {
                                ForEach(0..<5) { i in
                                    Image(systemName: i < origami.dif ? "star.fill" : "star")
                                        .foregroundColor(i < origami.dif ? .themeIndigo : .gray.opacity(0.3))
                                        .font(.title3)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // お気に入りボタン（独立してタップ可能に）
                        Button(action: {
                            favoriteManager.toggleFavorite(origamiCode: origami.code)
                        }) {
                            Image(systemName: favoriteManager.isFavorite(origamiCode: origami.code) ? "heart.fill" : "heart")
                                .foregroundColor(favoriteManager.isFavorite(origamiCode: origami.code) ? .themeVermilion : .gray)
                                .font(.title)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // 写真変更ボタン（完了済みのみ）
                        if completionManager.isCompleted(origamiCode: origami.code) {
                            Button(action: {
                                selectedOrigamiCode = origami.code
                                showingPhotoPickerSheet = true
                            }) {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.themeIndigo)
                                    .font(.title)
                                    .padding(.leading, 12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(16)
            .washiStyle() // 木札風スタイル
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 下部メニューバー
    private func bottomMenuBar() -> some View {
        HStack(spacing: 0) {
            // エラー修正: ViewModeManager.ViewMode.list を使用
            tabButton(icon: "list.bullet.rectangle", text: "list_view", mode: ViewModeManager.ViewMode.list)
            
            Rectangle().fill(Color.themeSumi.opacity(0.1)).frame(width: 1, height: 30)
            
            tabButton(icon: "square.grid.2x2", text: "gallery_view", mode: ViewModeManager.ViewMode.gallery)
        }
        .frame(height: 60)
        .background(Color.themeWashi.opacity(0.95))
        .overlay(Rectangle().fill(Color.themeSumi.opacity(0.1)).frame(height: 1), alignment: .top)
    }
    
    private func tabButton(icon: String, text: String, mode: ViewModeManager.ViewMode) -> some View {
        let isSelected = viewModeManager.selectedViewMode == mode
        return Button(action: { viewModeManager.setViewMode(mode) }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(languageManager.localizedString(text))
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundColor(isSelected ? .themeIndigo : .gray)
            .background(isSelected ? Color.themeIndigo.opacity(0.05) : Color.clear)
        }
    }
}

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
