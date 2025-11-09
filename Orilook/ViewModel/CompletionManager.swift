import SwiftUI

class CompletionManager: ObservableObject {
    @Published private var completedOrigami: Set<String> = []
    private let userDefaultsKey = "completedOrigami"
    
    init() {
        loadCompletedOrigami()
    }
    
    // 作品を完成済みとしてマーク
    func markAsCompleted(origamiCode: String) {
        completedOrigami.insert(origamiCode)
        saveCompletedOrigami()
    }
    
    // 作品が完成済みかどうかチェック
    func isCompleted(origamiCode: String) -> Bool {
        return completedOrigami.contains(origamiCode)
    }
    
    // 完成済みの作品数を取得
    var completedCount: Int {
        return completedOrigami.count
    }
    
    // 全ての完成状態をリセット
    func resetAll() {
        completedOrigami.removeAll()
        saveCompletedOrigami()
    }
    
    // UserDefaultsから完成状態を読み込み
    private func loadCompletedOrigami() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            completedOrigami = decoded
        }
    }
    
    // UserDefaultsに完成状態を保存
    private func saveCompletedOrigami() {
        if let encoded = try? JSONEncoder().encode(completedOrigami) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
}