import SwiftUI

struct OrigamiController: Identifiable, Hashable {
    var id = UUID()
    var code: String
    var name: String
    var step: Int
    var dif: Int
    var text: [String]
    var tag: [String]
    var fold: Bool
    var open: Bool
    var threed: Bool
    var AR: Bool
    
    init(code: String, name: String, step: Int, dif: Int, text: [String], tag: [String], fold: Bool, open: Bool, threed: Bool, AR: Bool) {
        self.code = code
        self.name = name
        self.step = step
        self.dif = dif
        self.text = text
        self.tag = tag
        self.fold = fold
        self.open = open
        self.threed = threed
        self.AR = AR
    }
    
    static func == (lhs: OrigamiController, rhs: OrigamiController) -> Bool {
        return lhs.code == rhs.code && lhs.name == rhs.name && lhs.step == rhs.step && lhs.dif == rhs.dif && lhs.text == rhs.text && lhs.tag == rhs.tag && lhs.fold == rhs.fold && lhs.open == rhs.open && lhs.threed == rhs.threed && lhs.AR == rhs.AR
    }
}

