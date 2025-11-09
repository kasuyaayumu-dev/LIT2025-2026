import SwiftUI

struct description_open: View {
    let index: Int
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var navigationManager: NavigationManager
    @State var stepnum = 0
    var body: some View {
        VStack{
            Text(getOrigamiArray(languageManager: languageManager)[index].name)
                .font(.system(size: 50))
            Image(getOrigamiArray(languageManager: languageManager)[index].code + "_open")
                .resizable()
                .scaledToFit()
            Text(getOrigamiArray(languageManager: languageManager)[index].name + languageManager.localizedString("opens"))
                .font(.system(size: 40))
            Button {

                    navigationManager.navigate(to: .done(index: index))

            } label: {
                Text( languageManager.localizedString("Done"))
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 400, height: 75)
                    .background(.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .shadow(color: .gray, radius: 15, x: 0, y: 5)
            }
            
        }
    }
}

#Preview {
    
}
