import SwiftUI

enum NavigationDestination: Hashable {
    case selectMode(index: Int)
    case descriptionFold(index: Int)
    case descriptionOpen(index: Int) 
    case descriptionTheed(index: Int)
    case descriptionAR(index: Int)
    case done(index: Int)
    case settings
}