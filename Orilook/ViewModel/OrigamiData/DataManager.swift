import SwiftUI

// プリセットの折り紙データを取得
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

// プリセット + ユーザー作品を統合して取得
func getAllOrigamiArray(languageManager: LanguageManager,
                        userOrigamiManager: UserOrigamiManager) -> [OrigamiController] {
    let presetOrigami = getOrigamiArray(languageManager: languageManager)
    let userOrigami = userOrigamiManager.userOrigami
    
    // プリセット作品を先に表示し、その後ユーザー作品を表示
    return presetOrigami + userOrigami
}

// 指定されたコードの作品を取得（プリセットとユーザー作品から検索）
func getOrigami(code: String,
                languageManager: LanguageManager,
                userOrigamiManager: UserOrigamiManager) -> OrigamiController? {
    let allOrigami = getAllOrigamiArray(languageManager: languageManager,
                                        userOrigamiManager: userOrigamiManager)
    return allOrigami.first { $0.code == code }
}
