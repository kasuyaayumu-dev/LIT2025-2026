import SwiftUI

struct FilterMenu: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var filterManager: FilterManager
    @State private var selectedTab: FilterMenuTab = .filter
    
    enum FilterMenuTab: CaseIterable {
        case filter, sort
        
        var title: String {
            switch self {
            case .filter: return "filter"
            case .sort: return "sort"
            }
        }
    }
    
    var body: some View {
        let origamiArray = getOrigamiArray(languageManager: languageManager)
        let availableGenres = filterManager.getAvailableGenres(from: origamiArray)
        
        NavigationStack {
            ZStack {
                // 背景：生成り色
                Color.themeWashi.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // カスタムタブバー
                    HStack(spacing: 0) {
                        ForEach(FilterMenuTab.allCases, id: \.self) { tab in
                            Button(action: { selectedTab = tab }) {
                                VStack(spacing: 8) {
                                    Text(languageManager.localizedString(tab.title))
                                        .font(.headline)
                                        .foregroundColor(selectedTab == tab ? .themeIndigo : .gray)
                                    
                                    // 選択中のタブの下線（筆で引いたような線）
                                    Rectangle()
                                        .fill(selectedTab == tab ? Color.themeIndigo : Color.clear)
                                        .frame(height: 3)
                                        .cornerRadius(1.5)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 16)
                                .background(Color.themeWashi.opacity(0.95))
                            }
                        }
                    }
                    .background(Color.white.opacity(0.5))
                    
                    // コンテンツエリア
                    ScrollView {
                        VStack(spacing: 24) {
                            if selectedTab == .filter {
                                filterContent(availableGenres: availableGenres)
                            } else {
                                sortContent
                            }
                        }
                        .padding(24)
                    }
                }
            }
            .navigationTitle(languageManager.localizedString("filter_and_sort"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        filterManager.clearFilters()
                        filterManager.setSortCategory(.original)
                    }) {
                        Text(languageManager.localizedString("clear_all"))
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.themeVermilion.opacity(0.1))
                            .foregroundColor(.themeVermilion)
                            .cornerRadius(4)
                    }
                }
            }
        }
    }
    
    // MARK: - フィルタ画面
    private func filterContent(availableGenres: [String]) -> some View {
        VStack(spacing: 24) {
            
            // お気に入りフィルタ
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: languageManager.localizedString("favorites"))
                
                Button(action: { filterManager.toggleFavoritesOnly() }) {
                    HStack {
                        // 和風チェックボックス
                        WashiCheckBox(isSelected: filterManager.showFavoritesOnly)
                        
                        Image(systemName: "heart.fill")
                            .foregroundColor(.themeVermilion) // 朱色
                        
                        Text(languageManager.localizedString("favorites_only"))
                            .foregroundColor(.themeSumi)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.white) // 内側の背景
                }
                .washiStyle()
            }
            
            // 難易度フィルタ
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: languageManager.localizedString("difficulty"))
                
                VStack(spacing: 12) {
                    // 1-5行目
                    ForEach(1...5, id: \.self) { row in
                        HStack(alignment: .top, spacing: 16) {
                            // 左側: 難易度1-5
                            difficultyRow(difficulty: row, maxStars: 5)
                            
                            // 右側: 難易度6-10 (存在する場合)
                            let rightDifficulty = row + 5
                            if rightDifficulty <= 10 {
                                // 区切り線
                                Rectangle().fill(Color.gray.opacity(0.2)).frame(width: 1)
                                
                                difficultyRow(difficulty: rightDifficulty, maxStars: 5)
                            } else {
                                Spacer().frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .padding(16)
                .washiStyle()
            }
            
            // ジャンルフィルタ
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: languageManager.localizedString("genre"))
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(availableGenres, id: \.self) { genre in
                        Button(action: { filterManager.toggleGenre(genre) }) {
                            HStack {
                                WashiCheckBox(isSelected: filterManager.selectedGenres.contains(genre))
                                
                                Text(languageManager.localizedString("genre_\(genre)"))
                                    .font(.caption)
                                    .foregroundColor(.themeSumi)
                                    .lineLimit(1)
                                
                                Spacer()
                            }
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(4)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        }
                    }
                }
            }
        }
    }
    
    // 難易度の行コンポーネント
    private func difficultyRow(difficulty: Int, maxStars: Int) -> some View {
        Button(action: { filterManager.toggleDifficulty(difficulty) }) {
            HStack(spacing: 8) {
                WashiCheckBox(isSelected: filterManager.selectedDifficulties.contains(difficulty))
                
                // 星表示
                HStack(spacing: 1) {
                    // 通常の星（5以下）
                    if difficulty <= 5 {
                        ForEach(0..<difficulty, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.themeIndigo)
                        }
                        ForEach(0..<(5-difficulty), id: \.self) { _ in
                            Image(systemName: "star")
                                .font(.system(size: 10))
                                .foregroundColor(.gray.opacity(0.4))
                        }
                    } else {
                        // 高難易度（朱色や紫で表現）
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.themeIndigo)
                        }
                        ForEach(0..<(difficulty-5), id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.themeVermilion) // 朱色
                        }
                    }
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - ソート画面
    private var sortContent: some View {
        VStack(spacing: 24) {
            // ソート項目
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: languageManager.localizedString("sort_category"))
                
                VStack(spacing: 0) {
                    ForEach(SortCategory.allCases, id: \.self) { category in
                        Button(action: { filterManager.setSortCategory(category) }) {
                            HStack {
                                WashiRadioButton(isSelected: filterManager.selectedSortCategory == category)
                                
                                Text(languageManager.localizedString(category.displayName))
                                    .foregroundColor(.themeSumi)
                                
                                Spacer()
                            }
                            .padding(16)
                            .background(Color.white)
                        }
                        
                        if category != SortCategory.allCases.last {
                            Divider().padding(.leading, 40)
                        }
                    }
                }
                .washiStyle()
            }
            
            // ソート順序（オリジナル以外の場合）
            if filterManager.selectedSortCategory != .original {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: languageManager.localizedString("sort_order"))
                    
                    VStack(spacing: 0) {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Button(action: { filterManager.setSortOrder(order) }) {
                                HStack {
                                    WashiRadioButton(isSelected: filterManager.selectedSortOrder == order)
                                    
                                    Text(languageManager.localizedString(order.displayName))
                                        .foregroundColor(.themeSumi)
                                    
                                    Spacer()
                                }
                                .padding(16)
                                .background(Color.white)
                            }
                            
                            if order != SortOrder.allCases.last {
                                Divider().padding(.leading, 40)
                            }
                        }
                    }
                    .washiStyle()
                }
            }
        }
    }
    
    // MARK: - カスタムUIパーツ
    
    // 和風チェックボックス（正方形）
    struct WashiCheckBox: View {
        let isSelected: Bool
        
        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isSelected ? Color.themeIndigo : Color.gray.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 20, height: 20)
                    .background(isSelected ? Color.themeIndigo.opacity(0.1) : Color.clear)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.themeIndigo)
                }
            }
        }
    }
    
    // 和風ラジオボタン（円形・朱色の印）
    struct WashiRadioButton: View {
        let isSelected: Bool
        
        var body: some View {
            ZStack {
                Circle()
                    .stroke(isSelected ? Color.themeVermilion : Color.gray.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 20, height: 20)
                
                if isSelected {
                    // 選択中は朱色の塗りつぶし（印鑑風）
                    Circle()
                        .fill(Color.themeVermilion)
                        .frame(width: 12, height: 12)
                }
            }
        }
    }
}
