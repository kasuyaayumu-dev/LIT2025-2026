import SwiftUI
import Foundation

// ユーザー作成の折り紙を管理するマネージャー
class UserOrigamiManager: ObservableObject {
    @Published var userOrigami: [OrigamiController] = []
    
    private let userDefaultsKey = "userOrigamiData"
    
    init() {
        loadUserOrigami()
    }
    
    // MARK: - CRUD Operations
    
    /// 新しいユーザー作品を追加
    func addOrigami(_ origami: OrigamiController) {
        var newOrigami = origami
        newOrigami.code = "user_\(UUID().uuidString)" // ユニークなコード生成
        userOrigami.append(newOrigami)
        saveUserOrigami()
    }
    
    /// ユーザー作品を更新
    func updateOrigami(_ origami: OrigamiController) {
        if let index = userOrigami.firstIndex(where: { $0.code == origami.code }) {
            userOrigami[index] = origami
            saveUserOrigami()
        }
    }
    
    /// ユーザー作品を削除
    func deleteOrigami(code: String) {
        userOrigami.removeAll { $0.code == code }
        saveUserOrigami()
    }
    
    /// 指定したコードの作品を取得
    func getOrigami(code: String) -> OrigamiController? {
        return userOrigami.first { $0.code == code }
    }
    
    /// ユーザー作品かどうかを判定
    func isUserOrigami(code: String) -> Bool {
        return code.hasPrefix("user_")
    }
    
    // MARK: - Export/Import (将来実装)
    
    /// 作品データをエクスポート（JSON形式）
    func exportOrigami(_ origami: OrigamiController) -> Data? {
        let exportData = ExportOrigamiData(origami: origami)
        return try? JSONEncoder().encode(exportData)
    }
    
    /// 作品データをインポート
    func importOrigami(from data: Data) -> Bool {
        guard let exportData = try? JSONDecoder().decode(ExportOrigamiData.self, from: data) else {
            return false
        }
        
        var origami = exportData.origami
        origami.code = "user_\(UUID().uuidString)" // 新しいコードを割り当て
        userOrigami.append(origami)
        saveUserOrigami()
        return true
    }
    
    /// 全ユーザー作品をエクスポート
    func exportAllOrigami() -> Data? {
        let exportData = ExportAllOrigamiData(origami: userOrigami)
        return try? JSONEncoder().encode(exportData)
    }
    
    // MARK: - Persistence
    
    private func saveUserOrigami() {
        // OrigamiControllerをCodableに対応させる必要がある
        let saveData = userOrigami.map { origami in
            SavedOrigamiData(
                code: origami.code,
                name: origami.name,
                step: origami.step,
                dif: origami.dif,
                text: origami.text,
                tag: origami.tag,
                fold: origami.fold,
                open: origami.open,
                threed: origami.threed,
                AR: origami.AR
            )
        }
        
        if let encoded = try? JSONEncoder().encode(saveData) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadUserOrigami() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([SavedOrigamiData].self, from: data) else {
            return
        }
        
        userOrigami = decoded.map { data in
            OrigamiController(
                code: data.code,
                name: data.name,
                step: data.step,
                dif: data.dif,
                text: data.text,
                tag: data.tag,
                fold: data.fold,
                open: data.open,
                threed: data.threed,
                AR: data.AR
            )
        }
    }
}

// MARK: - Codable Models

/// UserDefaultsに保存するためのCodable対応モデル
struct SavedOrigamiData: Codable {
    let code: String
    let name: String
    let step: Int
    let dif: Int
    let text: [String]
    let tag: [String]
    let fold: Bool
    let open: Bool
    let threed: Bool
    let AR: Bool
}

/// エクスポート用のデータ構造（単一作品）
struct ExportOrigamiData: Codable {
    let version: String = "1.0"
    let origami: OrigamiController
    let exportDate: Date = Date()
}

/// エクスポート用のデータ構造（全作品）
struct ExportAllOrigamiData: Codable {
    let version: String = "1.0"
    let origami: [OrigamiController]
    let exportDate: Date = Date()
}

// MARK: - OrigamiController Extension

extension OrigamiController: Codable {
    enum CodingKeys: String, CodingKey {
        case code, name, step, dif, text, tag, fold, open, threed, AR
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.code = try container.decode(String.self, forKey: .code)
        self.name = try container.decode(String.self, forKey: .name)
        self.step = try container.decode(Int.self, forKey: .step)
        self.dif = try container.decode(Int.self, forKey: .dif)
        self.text = try container.decode([String].self, forKey: .text)
        self.tag = try container.decode([String].self, forKey: .tag)
        self.fold = try container.decode(Bool.self, forKey: .fold)
        self.open = try container.decode(Bool.self, forKey: .open)
        self.threed = try container.decode(Bool.self, forKey: .threed)
        self.AR = try container.decode(Bool.self, forKey: .AR)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        try container.encode(name, forKey: .name)
        try container.encode(step, forKey: .step)
        try container.encode(dif, forKey: .dif)
        try container.encode(text, forKey: .text)
        try container.encode(tag, forKey: .tag)
        try container.encode(fold, forKey: .fold)
        try container.encode(open, forKey: .open)
        try container.encode(threed, forKey: .threed)
        try container.encode(AR, forKey: .AR)
    }
}
