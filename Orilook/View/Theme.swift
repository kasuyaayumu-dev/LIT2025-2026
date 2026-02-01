import SwiftUI

// 和風カラーパレットとスタイル定義
extension Color {
    // 背景：生成り色（和紙）
    static let themeWashi = Color(red: 0.97, green: 0.96, blue: 0.94)
    // 背景サブ：少し濃い生成り（区切り用）
    static let themeWashiDark = Color(red: 0.92, green: 0.91, blue: 0.89)
    // 文字：濃墨（こずみ）
    static let themeSumi = Color(red: 0.2, green: 0.2, blue: 0.2)
    // アクセント：藍色
    static let themeIndigo = Color(red: 0.1, green: 0.25, blue: 0.4)
    // アクセント：朱色
    static let themeVermilion = Color(red: 0.8, green: 0.25, blue: 0.2)
    // アクセント：抹茶色（完了済みなど）
    static let themeMatcha = Color(red: 0.4, green: 0.5, blue: 0.2)
}

// 和紙カード風のスタイル定義
struct WashiCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .cornerRadius(4) // 角を少しだけ丸める（紙の鋭さを残す）
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 1, y: 2) // 浮き感のある影
    }
}

extension View {
    func washiStyle() -> some View {
        self.modifier(WashiCardModifier())
    }
}
