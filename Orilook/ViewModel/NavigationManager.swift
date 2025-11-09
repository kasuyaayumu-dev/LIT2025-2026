import SwiftUI

class NavigationManager: ObservableObject {
    @Published var path: [NavigationDestination] = []
    
    func popToRoot() {
        path = []
    }
    
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    func navigate(to destination: NavigationDestination) {
        path.append(destination)
    }
}