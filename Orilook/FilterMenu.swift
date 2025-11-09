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
            VStack(spacing: 0) {
                // タブバーとナビゲーションの間にスペースを追加
                Spacer()
                    .frame(height: 8)
                
                // タブバー
                HStack(spacing: 0) {
                    ForEach(FilterMenuTab.allCases, id: \.self) { tab in
                        Text(languageManager.localizedString(tab.title))
                            .font(.headline)
                            .foregroundColor(selectedTab == tab ? .blue : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(selectedTab == tab ? Color.blue.opacity(0.1) : Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTab = tab
                            }
                    }
                }
                .background(Color.gray.opacity(0.1))
                
                // タブコンテンツ
                if selectedTab == .filter {
                    filterContent(availableGenres: availableGenres)
                } else {
                    sortContent
                }
            }
            .navigationTitle(languageManager.localizedString("filter_and_sort"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(languageManager.localizedString("clear_all")) {
                        filterManager.clearFilters()
                        filterManager.setSortCategory(.original)
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
    
    private func filterContent(availableGenres: [String]) -> some View {
        List {
                // お気に入りセクション
                Section {
                    HStack(spacing: 8) {
                        Button(action: {
                            filterManager.toggleFavoritesOnly()
                        }) {
                            Image(systemName: filterManager.showFavoritesOnly ? "checkmark.square.fill" : "square")
                                .foregroundColor(filterManager.showFavoritesOnly ? .blue : .gray)
                                .font(.system(size: 18))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 16))
                            
                            Text(languageManager.localizedString("favorites_only"))
                                .font(.caption)
                        }
                        
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        filterManager.toggleFavoritesOnly()
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text(languageManager.localizedString("favorites"))
                        .font(.headline)
                }
                // 難易度セクション
                Section {
                    VStack(spacing: 16) {
                        // 1行目: 難易度0 と 難易度6
                        HStack(alignment: .top, spacing: 20) {
                            // 左側: 難易度0（チュートリアル）
                            HStack(spacing: 8) {
                                Button(action: {
                                    filterManager.toggleDifficulty(0)
                                }) {
                                    Image(systemName: filterManager.selectedDifficulties.contains(0) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(filterManager.selectedDifficulties.contains(0) ? .blue : .gray)
                                        .font(.system(size: 18))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text(languageManager.localizedString("tutorial"))
                                    .font(.caption)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                filterManager.toggleDifficulty(0)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // 右側: 難易度6
                            HStack(spacing: 8) {
                                Button(action: {
                                    filterManager.toggleDifficulty(6)
                                }) {
                                    Image(systemName: filterManager.selectedDifficulties.contains(6) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(filterManager.selectedDifficulties.contains(6) ? .blue : .gray)
                                        .font(.system(size: 18))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 2) {
                                        ForEach(0..<5, id: \.self) { _ in
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.black)
                                                .font(.system(size: 12))
                                        }
                                    }
                                    HStack(spacing: 2) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.purple)
                                            .font(.system(size: 12))
                                    }
                                }
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                filterManager.toggleDifficulty(6)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // 2-6行目: 難易度1-5 と 難易度7-10, 空
                        ForEach(1...5, id: \.self) { row in
                            HStack(alignment: .top, spacing: 20) {
                                // 左側: 難易度1-5
                                HStack(spacing: 8) {
                                    Button(action: {
                                        filterManager.toggleDifficulty(row)
                                    }) {
                                        Image(systemName: filterManager.selectedDifficulties.contains(row) ? "checkmark.square.fill" : "square")
                                            .foregroundColor(filterManager.selectedDifficulties.contains(row) ? .blue : .gray)
                                            .font(.system(size: 18))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    HStack(spacing: 2) {
                                        ForEach(0..<row, id: \.self) { _ in
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.black)
                                                .font(.system(size: 12))
                                        }
                                        ForEach(0..<(5-row), id: \.self) { _ in
                                            Image(systemName: "star")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 12))
                                        }
                                    }
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    filterManager.toggleDifficulty(row)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // 右側: 難易度7-10 または空
                                let rightDifficulty = row + 6
                                if rightDifficulty <= 10 {
                                    HStack(spacing: 8) {
                                        Button(action: {
                                            filterManager.toggleDifficulty(rightDifficulty)
                                        }) {
                                            Image(systemName: filterManager.selectedDifficulties.contains(rightDifficulty) ? "checkmark.square.fill" : "square")
                                                .foregroundColor(filterManager.selectedDifficulties.contains(rightDifficulty) ? .blue : .gray)
                                                .font(.system(size: 18))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 2) {
                                                ForEach(0..<5, id: \.self) { _ in
                                                    Image(systemName: "star.fill")
                                                        .foregroundColor(.black)
                                                        .font(.system(size: 12))
                                                }
                                            }
                                            HStack(spacing: 2) {
                                                ForEach(0..<(rightDifficulty-5), id: \.self) { _ in
                                                    Image(systemName: "star.fill")
                                                        .foregroundColor(.purple)
                                                        .font(.system(size: 12))
                                                }
                                            }
                                        }
                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        filterManager.toggleDifficulty(rightDifficulty)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    Spacer()
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text(languageManager.localizedString("difficulty"))
                        .font(.headline)
                }
                
                // ジャンルセクション
                Section {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(availableGenres, id: \.self) { genre in
                            HStack(spacing: 8) {
                                Button(action: {
                                    filterManager.toggleGenre(genre)
                                }) {
                                    Image(systemName: filterManager.selectedGenres.contains(genre) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(filterManager.selectedGenres.contains(genre) ? .blue : .gray)
                                        .font(.system(size: 18))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text(languageManager.localizedString("genre_\(genre)"))
                                    .font(.caption)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                filterManager.toggleGenre(genre)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text(languageManager.localizedString("genre"))
                        .font(.headline)
                }
            }
        }
    
    private var sortContent: some View {
        List {
            // ソート項目セクション
            Section {
                ForEach(SortCategory.allCases, id: \.self) { category in
                    HStack {
                        Button(action: {
                            filterManager.setSortCategory(category)
                        }) {
                            HStack {
                                Image(systemName: filterManager.selectedSortCategory == category ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(filterManager.selectedSortCategory == category ? .blue : .gray)
                                    .font(.system(size: 20))
                                
                                Text(languageManager.localizedString(category.displayName))
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        filterManager.setSortCategory(category)
                    }
                }
            } header: {
                Text(languageManager.localizedString("sort_category"))
                    .font(.headline)
            }
            
            // ソート順序セクション（元の順序以外の場合のみ表示）
            if filterManager.selectedSortCategory != .original {
                Section {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        HStack {
                            Button(action: {
                                filterManager.setSortOrder(order)
                            }) {
                                HStack {
                                    Image(systemName: filterManager.selectedSortOrder == order ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(filterManager.selectedSortOrder == order ? .blue : .gray)
                                        .font(.system(size: 20))
                                    
                                    Text(languageManager.localizedString(order.displayName))
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            filterManager.setSortOrder(order)
                        }
                    }
                } header: {
                    Text(languageManager.localizedString("sort_order"))
                        .font(.headline)
                }
            }
        }
    }
}