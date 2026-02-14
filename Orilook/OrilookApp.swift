import SwiftUI

@main
struct OrilookApp: App {
    // 各マネージャーの初期化
    @StateObject var languageManager = LanguageManager()
    @StateObject var soundManager = SoundManager()
    @StateObject var tutorialManager = TutorialManager()
    @StateObject var favoriteManager = FavoriteManager()
    @StateObject var imageManager = ImageManager()
    @StateObject var completionManager = CompletionManager()
    @StateObject var navigationManager = NavigationManager()
    @StateObject var viewModeManager = ViewModeManager()
    @StateObject var filterManager = FilterManager()

    var body: some Scene {
        WindowGroup {
            CView()
                .environmentObject(languageManager)
                .environmentObject(soundManager)
                .environmentObject(tutorialManager)
                .environmentObject(favoriteManager)
                .environmentObject(imageManager)
                .environmentObject(completionManager)
                .environmentObject(navigationManager)
                .environmentObject(viewModeManager)
                .environmentObject(filterManager)
                // 【重要】チュートリアル用の座標空間をここで定義します
                .coordinateSpace(name: "tutorialSpace")
        }
    }
}
