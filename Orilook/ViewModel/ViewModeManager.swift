import SwiftUI

enum ViewMode: String, CaseIterable {
    case list = "list"
    case gallery = "gallery"
    
    var iconName: String {
        switch self {
        case .list: return "list.bullet"
        case .gallery: return "grid"
        }
    }
    
    var displayName: String {
        switch self {
        case .list: return "list_view"
        case .gallery: return "gallery_view"
        }
    }
}

class ViewModeManager: ObservableObject {
    @Published var selectedViewMode: ViewMode = .list
    
    // 表示モードを設定
    func setViewMode(_ viewMode: ViewMode) {
        selectedViewMode = viewMode
    }
    
    // 表示モードを切り替え
    func toggleViewMode() {
        switch selectedViewMode {
        case .list:
            selectedViewMode = .gallery
        case .gallery:
            selectedViewMode = .list
        }
    }
}