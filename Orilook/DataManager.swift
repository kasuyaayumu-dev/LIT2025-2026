import SwiftUI

func getOrigamiArray(languageManager: LanguageManager) -> [OrigamiController] {
    return [
        OrigamiController(
            code: "crane",
            name: languageManager.localizedString("crane"),
            step: 2,
            dif: 2, 
            text: [
                languageManager.localizedString("crane1"),
                languageManager.localizedString("crane2")
            ], 
            tag: ["traditional", "animals", "simple"], 
            fold: true, open: true, threed: true, AR: true
        ),
        OrigamiController(
            code: "fortune", 
            name: languageManager.localizedString("fortune"), 
            step: 7, 
            dif: 1, 
            text: [
                languageManager.localizedString("fortune1"),
                languageManager.localizedString("fortune2"),
                languageManager.localizedString("fortune3"),
                languageManager.localizedString("fortune4"),
                languageManager.localizedString("fortune5"),
                languageManager.localizedString("fortune6"),
                languageManager.localizedString("fortune7")
            ], 
            tag: ["traditional", "toys", "simple"], 
            fold: true, open: true, threed: true, AR: true
        ),
    ]
}

