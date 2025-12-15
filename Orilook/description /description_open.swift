import SwiftUI

struct description_open: View {
    // 【修正】Intではなく、OrigamiControllerを直接受け取る
    let origami: OrigamiController
    
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        VStack{
            // 【修正】配列インデックスではなく、受け取ったデータ(origami)を使用
            Text(origami.name)
                .font(.system(size: 50))
            
            // 【修正】画像ファイル名もコードから生成
            Image(origami.code + "_open")
                .resizable()
                .scaledToFit()
            
            Text(origami.name + languageManager.localizedString("opens"))
                .font(.system(size: 40))
            
            Button {
                // 【修正】ここがエラーの原因です。indexではなくorigamiを渡します
                navigationManager.navigate(to: .done(origami: origami))
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
