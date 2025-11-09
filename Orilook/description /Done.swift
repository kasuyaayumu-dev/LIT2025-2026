import SwiftUI

struct Done: View{
    let index: Int
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var completionManager: CompletionManager
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var imageManager: ImageManager
    @State private var showingPhotoPickerSheet = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        VStack(spacing: 30){
            Text(getOrigamiArray(languageManager: languageManager)[index].name)
                .font(.system(size: 50))
            CustomImageView(origamiCode: getOrigamiArray(languageManager: languageManager)[index].code)
                .scaledToFit()
            Text(languageManager.localizedString("congratulations"))
                .font(.system(size: 40))
            
            VStack(spacing: 20) {
                Button {
                    showingPhotoPickerSheet = true
                } label: {
                    Text(languageManager.localizedString("pic_select"))
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 400, height: 100)
                        .background(.yellow)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .shadow(color: .gray, radius: 15, x: 0, y: 5)
                }
                
                Button(action: {
                    navigationManager.popToRoot()
                }) {
                    Text(languageManager.localizedString("back_to_list"))
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 400, height: 100)
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .shadow(color: .cyan, radius: 15, x: 0, y: 5)
                }
            }
        }
        .onAppear {
            let origami = getOrigamiArray(languageManager: languageManager)[index]
            completionManager.markAsCompleted(origamiCode: origami.code)
        }
        .onChange(of: selectedImage) { image in
            if let image = image {
                let origami = getOrigamiArray(languageManager: languageManager)[index]
                imageManager.saveUserImage(image, for: origami.code)
            }
        }
        .sheet(isPresented: $showingPhotoPickerSheet) {
            PhotoPickerSheet(
                selectedImage: $selectedImage,
                isPresented: $showingPhotoPickerSheet
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    navigationManager.navigate(to: .settings)
                }) {
                    VStack{
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .frame(width: 40,height: 40)
                            .foregroundColor(.black)
                    }
                }
            }
        }
    }
}
