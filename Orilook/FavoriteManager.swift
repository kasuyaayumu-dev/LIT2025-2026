import SwiftUI
import Foundation

class FavoriteManager: ObservableObject {
    @Published private(set) var favoriteOrigami: Set<String> = []
    
    private let favoritesKey = "favoriteOrigami"
    
    init() {
        loadFavorites()
    }
    
    func addToFavorites(origamiCode: String) {
        favoriteOrigami.insert(origamiCode)
        saveFavorites()
    }
    
    func removeFromFavorites(origamiCode: String) {
        favoriteOrigami.remove(origamiCode)
        saveFavorites()
    }
    
    func toggleFavorite(origamiCode: String) {
        if isFavorite(origamiCode: origamiCode) {
            removeFromFavorites(origamiCode: origamiCode)
        } else {
            addToFavorites(origamiCode: origamiCode)
        }
    }
    
    func isFavorite(origamiCode: String) -> Bool {
        return favoriteOrigami.contains(origamiCode)
    }
    
    func resetAll() {
        favoriteOrigami.removeAll()
        saveFavorites()
    }
    
    private func saveFavorites() {
        let favorites = Array(favoriteOrigami)
        UserDefaults.standard.set(favorites, forKey: favoritesKey)
    }
    
    private func loadFavorites() {
        if let favorites = UserDefaults.standard.array(forKey: favoritesKey) as? [String] {
            favoriteOrigami = Set(favorites)
        }
    }
}