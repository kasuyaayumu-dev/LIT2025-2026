import SwiftUI
import SceneKit

struct description_theed: View {
    let index: Int
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var navigationManager: NavigationManager
    @State var stepnum = 0
    var body: some View {
        VStack{
            Text(getOrigamiArray(languageManager: languageManager)[index].name)
                .font(.system(size: 50))
            USDZViewer3D(getOrigamiArray(languageManager: languageManager)[index].code + "3d" + String(stepnum), width: 600, height: 600)
            Text(getOrigamiArray(languageManager: languageManager)[index].text[stepnum])
                .font(.system(size: 40))
            HStack(spacing: 40) {
                Button {
                    if stepnum > 0 {
                        stepnum -= 1
                    }
                } label: {
                    Text(languageManager.localizedString("Back"))
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 100)
                        .background(stepnum > 0 ? .blue : .gray)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .shadow(color: stepnum > 0 ? .cyan : .gray, radius: 15, x: 0, y: 5)
                }
                .disabled(stepnum <= 0)
                
                Button {
                    if stepnum < getOrigamiArray(languageManager: languageManager)[index].step - 1 {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            stepnum += 1
                        }
                    } else {
                        navigationManager.navigate(to: .done(index: index))
                    }
                } label: {
                    Text(stepnum < getOrigamiArray(languageManager: languageManager)[index].step - 1 ? languageManager.localizedString("Forward") : languageManager.localizedString("Done"))
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 100)
                        .background(stepnum < getOrigamiArray(languageManager: languageManager)[index].step - 1 ? .red : .yellow)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .shadow(color: stepnum < getOrigamiArray(languageManager: languageManager)[index].step - 1 ? .pink : .gray, radius: 15, x: 0, y: 5)
                }
            }
        }
    }
}
