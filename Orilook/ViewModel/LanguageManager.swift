import Foundation
import SwiftUI

class LanguageManager: ObservableObject {
    @Published var language: LanguageType = .japanese {
        didSet {
            // 言語が変更されたら保存
            saveLanguageToUserDefaults()
        }
    }   
    @Published var isTransitioning: Bool = false
    
    // アニメーション時間を設定する関数
    func setTransitionDuration(_ duration: Double) -> Double {
        return duration
    }
    
    init() {
        // 初期化時にシステム言語または保存された言語を設定
        loadLanguageFromUserDefaults()
    }
    
    // UserDefaultsから言語設定を読み込み
    private func loadLanguageFromUserDefaults() {
        if let savedLanguageRawValue = UserDefaults.standard.object(forKey: "AppLanguage") as? String,
           let savedLanguageType = LanguageType.fromRawValue(savedLanguageRawValue) {
            // 保存された言語設定がある場合はそれを使用
            self.language = savedLanguageType
        } else {
            // 保存された設定がない場合はシステム言語を使用
            self.language = getSystemLanguage()
            // 初回設定をUserDefaultsに保存
            saveLanguageToUserDefaults()
        }
    }
    
    // システム言語を取得してLanguageTypeに変換
    private func getSystemLanguage() -> LanguageType {
        let systemLanguageCode = Locale.preferredLanguages.first ?? "ja"
        
        // システム言語コードから対応するLanguageTypeを判定
        if systemLanguageCode.hasPrefix("en") {
            return .english
        } else if systemLanguageCode.hasPrefix("ja") {
            return .japanese
        } else {
            // デフォルトは日本語
            return .japanese
        }
    }
    
    // 言語設定をUserDefaultsに保存
    private func saveLanguageToUserDefaults() {
        UserDefaults.standard.set(language.rawValue, forKey: "AppLanguage")
    }
    
    // 言語を手動で変更するメソッド（アニメーション付き）
    func changeLanguage(to newLanguage: LanguageType, animationDuration: Double = 0.3) {
        isTransitioning = true
        withAnimation(.easeInOut(duration: animationDuration)) {
            language = newLanguage
        }
        
        // アニメーション完了後にフラグをリセット
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            self.isTransitioning = false
        }
    }
    
    // ローカライズされたテキストを取得するメソッド
    func localizedString(_ key: String) -> String {
        guard let bundlePath = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: bundlePath) else {
            return NSLocalizedString(key, bundle: Bundle.main, value: key, comment: "")
        }
        return NSLocalizedString(key, bundle: bundle, value: key, comment: "")
    }
    
    // システム言語に戻すメソッド
    func resetToSystemLanguage() {
        language = getSystemLanguage()
    }
}

enum LanguageType: CaseIterable {
    case english, japanese
    
    var locale: Locale {
        switch self {
        case .english: Locale(identifier: "en")
        case .japanese: Locale(identifier: "ja")
        }
    }
    
    // 文字列値を取得（UserDefaults保存用）
    var rawValue: String {
        switch self {
        case .english: return "en"
        case .japanese: return "ja"
        }
    }
    
    // 文字列からLanguageTypeを生成
    static func fromRawValue(_ rawValue: String) -> LanguageType? {
        switch rawValue {
        case "en": return .english
        case "ja": return .japanese
        default: return nil
        }
    }
    
    // 表示名を取得
    var displayName: String {
        switch self {
        case .english: return "English"
        case .japanese: return "日本語"
        }
    }
}
