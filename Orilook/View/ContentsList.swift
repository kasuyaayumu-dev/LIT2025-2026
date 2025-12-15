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
    @EnvironmentObject var userOrigamiManager: UserOrigamiManager
    
    @State private var isTutorialPresented = false
    @State private var showingPhotoPickerSheet = false
    @State private var selectedImage: UIImage?
    @State private var selectedOrigamiCode: String?
    
    var body: some View {
        // 全ての折り紙データを取得（プリセット＋ユーザー作品）
        let origamiArray = getAllOrigamiArray(languageManager: languageManager, userOrigamiManager: userOrigamiManager)
        let filteredArray = filterManager.filterAndSortOrigami(origamiArray, languageManager: languageManager, favoriteManager: favoriteManager)
        
        NavigationStack(path: $navigationManager.path) {
            VStack(spacing: 0) {
                // コンテンツ表示
                if viewModeManager.selectedViewMode == .list {
                    listView(filteredArray: filteredArray)
                } else {
                    GalleryView(origamiArray: filteredArray)
                }
                
                // 下部メニューバー
                bottomMenuBar()
            }
            .background(Color(.systemBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        navigationManager.navigate(to: .userNew(index: 0))
                    }) {
                        Image(systemName: "plus.circle")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.black)
                    }
                }
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
                case .selectMode(let origami):
                    select_mode(origami: origami)
                case .descriptionFold(let origami):
                    description_fold(origami: origami)
                case .descriptionOpen(let origami):
                    description_open(origami: origami)
                case .descriptionTheed(let origami):
                    DescriptionThreed(origami: origami)
                case .descriptionAR(let origami):
                    description_AR(origami: origami)
                case .done(let origami):
                    Done(origami: origami)
                case .settings:
                    settings()
                case .userNew(_):
                    UserNew(editingOrigamiCode: nil)
                }
            }
        }
        .onAppear {
            soundManager.startBGMAfterLoading()
        }
        .tutorial(flow: .contentsList, autoStart: true)
    }
    
    private func listView(filteredArray: [OrigamiController]) -> some View {
        List {
            ForEach(filteredArray) { origami in
                Button(action: {
                    // 【重要】インデックスではなく、データそのものを渡す
                    navigationManager.navigate(to: .selectMode(origami: origami))
                }) {
                    HStack(spacing: 40) {
                        CustomImageView(origamiCode: origami.code)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 400, height: 300)
                            .clipped()
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text(origami.name)
                                    .font(.system(size: 40))
                                    .foregroundStyle(.black)
                                Spacer()
                                
                                if completionManager.isCompleted(origamiCode: origami.code) {
                                    Button(action: {
                                        selectedOrigamiCode = origami.code
                                        showingPhotoPickerSheet = true
                                    }) {
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.trailing, 8)
                                    
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title)
                                        .padding(.trailing, 8)
                                }
                                
                                Button(action: {
                                    favoriteManager.toggleFavorite(origamiCode: origami.code)
                                }) {
                                    Image(systemName: favoriteManager.isFavorite(origamiCode: origami.code) ? "heart.fill" : "heart")
                                        .foregroundColor(.red)
                                        .font(.title2)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .tutorialTarget(id: "favorite_button")
                            }
                            HStack {
                                if origami.dif == 0 {
                                    Text(languageManager.localizedString("tutorial"))
                                        .font(.body)
                                        .foregroundColor(.blue)
                                } else if origami.dif <= 5 {
                                    ForEach(0..<origami.dif, id: \.self) { _ in
                                        Image(systemName: "star.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 40)
                                            .foregroundColor(.black)
                                    }
                                    ForEach(0..<5-origami.dif, id: \.self) { _ in
                                        Image(systemName: "star")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 40)
                                            .foregroundColor(.black)
                                    }
                                } else {
                                    ForEach(1...5, id: \.self) { _ in
                                        Image(systemName: "star.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 40)
                                            .foregroundColor(.black)
                                    }
                                }
                            }
                            if origami.dif > 5 {
                                HStack {
                                    ForEach(0..<origami.dif-5, id: \.self) { _ in
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
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 0.5)
            
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
