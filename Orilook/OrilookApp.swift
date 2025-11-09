import SwiftUI

@main
struct OrilookApp: App {
    @StateObject var languageManager = LanguageManager()
    @StateObject var filterManager = FilterManager()
    @StateObject var viewModeManager = ViewModeManager()
    @StateObject var completionManager = CompletionManager()
    @StateObject var navigationManager = NavigationManager()
    @StateObject var imageManager = ImageManager()
    @StateObject var favoriteManager = FavoriteManager()
    @StateObject var tutorialManager = TutorialManager()
    @StateObject var soundManager = SoundManager()
    
    var body: some Scene {
        WindowGroup {
            CView()
                .environmentObject(languageManager)
                .environmentObject(filterManager)
                .environmentObject(viewModeManager)
                .environmentObject(completionManager)
                .environmentObject(navigationManager)
                .environmentObject(imageManager)
                .environmentObject(favoriteManager)
                .environmentObject(tutorialManager)
                .environmentObject(soundManager)
                .environment(\.locale, languageManager.language.locale)
        }
    }
}
