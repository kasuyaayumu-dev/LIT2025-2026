import SwiftUI

struct CustomImageView: View {
    let origamiCode: String
    @EnvironmentObject var imageManager: ImageManager
    
    var body: some View {
        Group {
            if let userImage = imageManager.getImage(for: origamiCode) {
                Image(uiImage: userImage)
                    .resizable()
            } else {
                Image(origamiCode)
                    .resizable()
            }
        }
    }
}