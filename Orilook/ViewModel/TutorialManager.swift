import SwiftUI

// StepとFlowの定義
struct TutorialStep {
    let id: String
    let title: String
    let message: String
    let targetView: String? // ポイントアウトするID
    let position: TutorialPosition? // 位置指定（任意）
}

// 位置指定用の列挙型（Overlay側で使う場合）
enum TutorialPosition {
    case center, top, bottom, topLeft, topRight, bottomLeft, bottomRight
}

enum TutorialFlow: String, CaseIterable {
    case contentsList = "contents_list"
    case galleryView = "gallery_view"
    case selectMode = "select_mode"
    case settings = "settings"
    case descriptionFold = "description_fold"
    case descriptionOpen = "description_open"
    case descriptionAR = "description_ar"
    case description3d = "description_3d" // 【追加】
    
    var steps: [TutorialStep] {
        switch self {
        case .contentsList:
            return [
                TutorialStep(id: "welcome", title: "tutorial_contents_welcome_title", message: "tutorial_contents_welcome_message", targetView: nil, position: .center),
                TutorialStep(id: "filter", title: "tutorial_contents_filter_title", message: "tutorial_contents_filter_message", targetView: "filter_button", position: .bottomLeft),
                TutorialStep(id: "viewmode", title: "tutorial_contents_viewmode_title", message: "tutorial_contents_viewmode_message", targetView: "view_mode_bar", position: .top)
            ]
        case .galleryView:
            return [
                TutorialStep(id: "intro", title: "tutorial_gallery_overview_title", message: "tutorial_gallery_overview_message", targetView: nil, position: .center),
                TutorialStep(id: "grid", title: "tutorial_gallery_selection_title", message: "tutorial_gallery_selection_message", targetView: "gallery_grid", position: .bottom)
            ]
        case .selectMode:
            return [
                TutorialStep(id: "intro", title: "tutorial_select_mode_overview_title", message: "tutorial_select_mode_overview_message", targetView: nil, position: .center),
                TutorialStep(id: "modes", title: "tutorial_select_mode_buttons_title", message: "tutorial_select_mode_buttons_message", targetView: "mode_buttons", position: .top),
                TutorialStep(id: "fav", title: "tutorial_contents_favorites_title", message: "tutorial_contents_favorites_message", targetView: "favorite_button", position: .bottomLeft)
            ]
        case .descriptionFold:
            return [
                TutorialStep(id: "intro", title: "tutorial_fold_overview_title", message: "tutorial_fold_overview_message", targetView: nil, position: .center),
                TutorialStep(id: "nav", title: "tutorial_fold_step_title", message: "tutorial_fold_step_message", targetView: "fold_nav", position: .top)
            ]
        case .descriptionOpen:
            return [
                TutorialStep(id: "intro", title: "tutorial_open_overview_title", message: "tutorial_open_overview_message", targetView: nil, position: .center)
            ]
        case .descriptionAR:
            return [
                TutorialStep(id: "intro", title: "tutorial_ar_overview_title", message: "tutorial_ar_overview_message", targetView: nil, position: .center),
                TutorialStep(id: "nav", title: "tutorial_fold_step_title", message: "tutorial_fold_step_message", targetView: "ar_nav", position: .top)
            ]
        case .description3d: // 【追加】3Dモード用のステップ
            return [
                TutorialStep(id: "intro", title: "tutorial_3d_overview_title", message: "tutorial_3d_overview_message", targetView: "3d_view", position: .bottom),
                TutorialStep(id: "nav", title: "tutorial_fold_step_title", message: "tutorial_fold_step_message", targetView: "3d_nav", position: .top)
            ]
        case .settings:
            return [
                TutorialStep(id: "lang", title: "tutorial_settings_language_title", message: "tutorial_settings_language_message", targetView: "language_setting", position: .bottom)
            ]
        }
    }
}

class TutorialManager: ObservableObject {
    @Published var isActive: Bool = false
    @Published var currentFlow: TutorialFlow?
    @Published var currentStepIndex: Int = 0
    @Published var hasCompletedTutorial: Set<String> = []
    
    private let key = "completedTutorials"
    
    init() {
        if let data = UserDefaults.standard.array(forKey: key) as? [String] {
            hasCompletedTutorial = Set(data)
        }
    }
    
    var currentStep: TutorialStep? {
        guard let flow = currentFlow, currentStepIndex < flow.steps.count else { return nil }
        return flow.steps[currentStepIndex]
    }
    
    func startTutorial(for flow: TutorialFlow, force: Bool = false) {
        if !force && hasCompletedTutorial.contains(flow.rawValue) { return }
        currentFlow = flow
        currentStepIndex = 0
        isActive = true
    }
    
    func nextStep() {
        guard let flow = currentFlow else { return }
        if currentStepIndex < flow.steps.count - 1 {
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
        UserDefaults.standard.set(Array(hasCompletedTutorial), forKey: key)
        isActive = false
        currentFlow = nil
    }
    
    func resetAllTutorials() {
        hasCompletedTutorial.removeAll()
        UserDefaults.standard.removeObject(forKey: key)
    }
}
