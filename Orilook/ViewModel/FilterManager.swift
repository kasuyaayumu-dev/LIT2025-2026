import SwiftUI

enum SortCategory: String, CaseIterable {
    case name = "name"
    case difficulty = "difficulty"
    case original = "original"
    
    var displayName: String {
        switch self {
        case .name: return "name_sort"
        case .difficulty: return "difficulty_sort"
        case .original: return "original_sort"
        }
    }
}

enum SortOrder: String, CaseIterable {
    case ascending = "ascending"
    case descending = "descending"
    
    var displayName: String {
        switch self {
        case .ascending: return "sort_ascending"
        case .descending: return "sort_descending"
        }
    }
}

class FilterManager: ObservableObject {
    @Published var selectedDifficulties: Set<Int> = []
    @Published var selectedGenres: Set<String> = []
    @Published var showFavoritesOnly: Bool = false
    @Published var isFilterMenuPresented: Bool = false
    @Published var selectedSortCategory: SortCategory = .original
    @Published var selectedSortOrder: SortOrder = .ascending
    
    // フィルタリング用の難易度設定
    func toggleDifficulty(_ difficulty: Int) {
        if selectedDifficulties.contains(difficulty) {
            selectedDifficulties.remove(difficulty)
        } else {
            selectedDifficulties.insert(difficulty)
        }
    }
    
    // フィルタリング用のジャンル設定（将来の拡張用）
    func toggleGenre(_ genre: String) {
        if selectedGenres.contains(genre) {
            selectedGenres.remove(genre)
        } else {
            selectedGenres.insert(genre)
        }
    }
    
    // お気に入り表示の切り替え
    func toggleFavoritesOnly() {
        showFavoritesOnly.toggle()
    }
    
    // フィルタリング条件をクリア
    func clearFilters() {
        selectedDifficulties.removeAll()
        selectedGenres.removeAll()
        showFavoritesOnly = false
    }
    
    // ソート種類を設定
    func setSortCategory(_ sortCategory: SortCategory) {
        selectedSortCategory = sortCategory
    }
    
    // ソート順序を設定
    func setSortOrder(_ sortOrder: SortOrder) {
        selectedSortOrder = sortOrder
    }
    
    // 折り紙配列をフィルタリングし、ソートする（言語管理のため）
    func filterAndSortOrigami(_ origamiArray: [OrigamiController], languageManager: LanguageManager, favoriteManager: FavoriteManager? = nil) -> [OrigamiController] {
        var filteredArray = origamiArray
        
        // お気に入りでフィルタリング
        if showFavoritesOnly, let favoriteManager = favoriteManager {
            filteredArray = filteredArray.filter { origami in
                favoriteManager.isFavorite(origamiCode: origami.code)
            }
        }
        
        // 難易度でフィルタリング
        if !selectedDifficulties.isEmpty {
            filteredArray = filteredArray.filter { origami in
                selectedDifficulties.contains(origami.dif)
            }
        }
        
        // ジャンルでフィルタリング
        if !selectedGenres.isEmpty {
            filteredArray = filteredArray.filter { origami in
                // 選択されたジャンルのいずれかが折り紙のタグに含まれているかチェック
                return selectedGenres.contains { genre in
                    origami.tag.contains(genre)
                }
            }
        }
        
        // ソート
        switch selectedSortCategory {
        case .name:
            filteredArray = sortByName(filteredArray, languageManager: languageManager)
        case .difficulty:
            filteredArray = sortByDifficulty(filteredArray)
        case .original:
            // 元の順序を保持
            break
        }
        
        return filteredArray
    }
    
    // 名前でソート（言語別対応）
    private func sortByName(_ array: [OrigamiController], languageManager: LanguageManager) -> [OrigamiController] {
        return array.sorted { (origami1: OrigamiController, origami2: OrigamiController) -> Bool in
            let result: ComparisonResult
            if languageManager.language == .japanese {
                // 日本語：ひらがな順
                result = origami1.name.localizedCompare(origami2.name)
            } else {
                // 英語：アルファベット順
                result = origami1.name.localizedCompare(origami2.name)
            }
            return selectedSortOrder == .ascending ? result == .orderedAscending : result == .orderedDescending
        }
    }
    
    // 難易度でソート
    private func sortByDifficulty(_ array: [OrigamiController]) -> [OrigamiController] {
        return array.sorted { (origami1: OrigamiController, origami2: OrigamiController) -> Bool in
            return selectedSortOrder == .ascending ? origami1.dif < origami2.dif : origami1.dif > origami2.dif
        }
    }
    
    // フィルターが適用されているかどうか
    var hasActiveFilters: Bool {
        return !selectedDifficulties.isEmpty || !selectedGenres.isEmpty || showFavoritesOnly
    }
    
    // 利用可能なジャンルを取得
    func getAvailableGenres(from origamiArray: [OrigamiController]) -> [String] {
        var allGenres: Set<String> = []
        for origami in origamiArray {
            for tag in origami.tag {
                allGenres.insert(tag)
            }
        }
        return Array(allGenres).sorted()
    }
}