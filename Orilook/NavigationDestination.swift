import SwiftUI

enum NavigationDestination: Hashable {
    // 【修正】index: Int ではなく origami: OrigamiController に変更
    case selectMode(origami: OrigamiController)
    case descriptionFold(origami: OrigamiController)
    case descriptionOpen(origami: OrigamiController)
    case descriptionTheed(origami: OrigamiController)
    case descriptionAR(origami: OrigamiController)
    case done(origami: OrigamiController)
    case settings
    case userNew(index: Int) // 新規作成は便宜上indexのままでOK
}
