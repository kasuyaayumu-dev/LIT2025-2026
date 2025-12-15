import SwiftUI

struct description_fold: View {
    // 【修正】IntではなくOrigamiControllerを受け取る
    let origami: OrigamiController
    
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var navigationManager: NavigationManager
    @State var stepnum = 0
    
    var body: some View {
        VStack{
            Text(origami.name)
                .font(.system(size: 36))
            
            // ユーザー作品の場合は画像ファイル名ルールをどうするか要検討ですが
            // 現状はプリセットと同じルールで読み込みます
            Image(origami.code + "2d" + String(stepnum))
                .resizable()
                .scaledToFit()
            
            if stepnum < origami.text.count {
                Text(origami.text[stepnum])
                    .font(.system(size: 40))
            }
            
            HStack(spacing: 40) {
                Button {
                    if stepnum > 0 {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            stepnum -= 1
                        }
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
                    if stepnum < origami.step - 1 {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            stepnum += 1
                        }
                    } else {
                        // 【修正】ここがエラーの原因でした。origamiを渡すように修正済み
                        navigationManager.navigate(to: .done(origami: origami))
                    }
                } label: {
                    Text(stepnum < origami.step - 1 ? languageManager.localizedString("Forward") : languageManager.localizedString("Done"))
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 100)
                        .background(stepnum < origami.step - 1 ? .red : .yellow)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .shadow(color: stepnum < origami.step - 1 ? .pink : .gray, radius: 15, x: 0, y: 5)
                }
            }
        }
    }
}
