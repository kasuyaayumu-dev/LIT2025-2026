import SwiftUI
import Foundation

// チュートリアルステップを定義
struct TutorialStep {
    let id: String
    let title: String
    let message: String
    let targetView: String? // ポイントアウトするビューのID
    let position: TutorialPosition
}

enum TutorialPosition {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case center
    case top
    case bottom
}

// 画面ごとのチュートリアルを定義
enum TutorialFlow: String, CaseIterable {
    case contentsList = "contents_list"
    case galleryView = "gallery_view"
    case selectMode = "select_mode"
    case settings = "settings"
    
    var steps: [TutorialStep] {
        switch self {
        case .contentsList:
            return [
                TutorialStep(
                    id: "welcome",
                    title: "tutorial_contents_welcome_title",
                    message: "tutorial_contents_welcome_message",
                    targetView: nil,
                    position: .center
                ),
                TutorialStep(
                    id: "filter_button",
                    title: "tutorial_contents_filter_title",
                    message: "tutorial_contents_filter_message",
                    targetView: "filter_button",
                    position: .topRight
                ),
                TutorialStep(
                    id: "settings_button", 
                    title: "tutorial_contents_settings_title",
                    message: "tutorial_contents_settings_message",
                    targetView: "settings_button",
                    position: .topRight
                ),
                TutorialStep(
                    id: "view_mode",
                    title: "tutorial_contents_viewmode_title", 
                    message: "tutorial_contents_viewmode_message",
                    targetView: "view_mode_bar",
                    position: .bottom
                ),
                TutorialStep(
                    id: "favorites",
                    title: "tutorial_contents_favorites_title",
                    message: "tutorial_contents_favorites_message", 
                    targetView: "favorite_button",
                    position: .topRight
                )
            ]
        case .galleryView:
            return [
                TutorialStep(
                    id: "gallery_overview",
                    title: "tutorial_gallery_overview_title",
                    message: "tutorial_gallery_overview_message",
                    targetView: nil,
                    position: .center
                ),
                TutorialStep(
                    id: "gallery_selection",
                    title: "tutorial_gallery_selection_title", 
                    message: "tutorial_gallery_selection_message",
                    targetView: "gallery_grid",
                    position: .topLeft
                ),
                TutorialStep(
                    id: "gallery_favorites",
                    title: "tutorial_gallery_favorites_title",
                    message: "tutorial_gallery_favorites_message", 
                    targetView: "gallery_favorite_button",
                    position: .topLeft
                )
            ]
        case .selectMode:
            return [
                TutorialStep(
                    id: "select_mode_overview",
                    title: "tutorial_select_mode_overview_title",
                    message: "tutorial_select_mode_overview_message",
                    targetView: nil,
                    position: .center
                ),
                TutorialStep(
                    id: "mode_buttons",
                    title: "tutorial_select_mode_buttons_title",
                    message: "tutorial_select_mode_buttons_message",
                    targetView: "mode_buttons",
                    position: .center
                ),
                TutorialStep(
                    id: "toolbar_buttons",
                    title: "tutorial_select_mode_toolbar_title", 
                    message: "tutorial_select_mode_toolbar_message",
                    targetView: "toolbar_buttons",
                    position: .topRight
                )
            ]
        case .settings:
            return [
                TutorialStep(
                    id: "settings_overview",
                    title: "tutorial_settings_overview_title",
                    message: "tutorial_settings_overview_message",
                    targetView: nil,
                    position: .center
                ),
                TutorialStep(
                    id: "language_setting",
                    title: "tutorial_settings_language_title",
                    message: "tutorial_settings_language_message",
                    targetView: "language_setting",
                    position: .center
                ),
                TutorialStep(
                    id: "sound_settings",
                    title: "tutorial_settings_sound_title",
                    message: "tutorial_settings_sound_message",
                    targetView: "sound_settings",
                    position: .center
                ),
                TutorialStep(
                    id: "progress_reset",
                    title: "tutorial_settings_reset_title",
                    message: "tutorial_settings_reset_message", 
                    targetView: "progress_reset",
                    position: .center
                )
            ]
        }
    }
}

class TutorialManager: ObservableObject {
    @Published var isActive: Bool = false
    @Published var currentFlow: TutorialFlow?
    @Published var currentStepIndex: Int = 0
    @Published var hasCompletedTutorial: Set<String> = []
    
    private let completedTutorialsKey = "completedTutorials"
    
    init() {
        loadCompletedTutorials()
    }
    
    var currentStep: TutorialStep? {
        guard let flow = currentFlow else { return nil }
        let steps = flow.steps
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }
    
    func startTutorial(for flow: TutorialFlow, force: Bool = false) {
        if !force && hasCompletedTutorial.contains(flow.rawValue) {
            return
        }
        
        currentFlow = flow
        currentStepIndex = 0
        isActive = true
    }
    
    func nextStep() {
        guard let flow = currentFlow else { return }
        let steps = flow.steps
        
        if currentStepIndex < steps.count - 1 {
            currentStepIndex += 1
        } else {
            completeTutorial()
        }
    }
    
    func skipTutorial() {
        completeTutorial()
    }
    
    private func completeTutorial() {
        guard let flow = currentFlow else { return }
        
        hasCompletedTutorial.insert(flow.rawValue)
        saveCompletedTutorials()
        
        // 状態を確実にリセット
        DispatchQueue.main.async {
            self.isActive = false
            self.currentFlow = nil
            self.currentStepIndex = 0
        }
    }
    
    func resetAllTutorials() {
        hasCompletedTutorial.removeAll()
        saveCompletedTutorials()
    }
    
    private func saveCompletedTutorials() {
        let tutorials = Array(hasCompletedTutorial)
        UserDefaults.standard.set(tutorials, forKey: completedTutorialsKey)
    }
    
    private func loadCompletedTutorials() {
        if let tutorials = UserDefaults.standard.array(forKey: completedTutorialsKey) as? [String] {
            hasCompletedTutorial = Set(tutorials)
        }
    }
}
