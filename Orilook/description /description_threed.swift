import SwiftUI
import SceneKit

struct DescriptionThreed: View { // ファイル名に合わせて struct 名を調整してください
    let origami: OrigamiController
    
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var favoriteManager: FavoriteManager
    @EnvironmentObject var tutorialManager: TutorialManager
    
    // 現在のステップ番号
    @State var stepnum = 0
    
    // 現在のステップのテキスト
    private var currentStepText: String {
        if stepnum < origami.text.count {
            return origami.text[stepnum]
        }
        return ""
    }
    
    // 最後のステップかどうか
    private var isLastStep: Bool {
        stepnum == origami.step - 1
    }
    
    var body: some View {
        ZStack {
            // 1. 背景：生成り色
            Color.themeWashi.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // ヘッダー
                VStack(spacing: 8) {
                    Text(origami.name)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.themeSumi)
                    
                    Text(languageManager.localizedString("3d"))
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                // メインコンテンツエリア
                GeometryReader { geometry in
                    VStack(spacing: 24) {
                        
                        // 2. 3Dビューアエリア（額装風）
                        ZStack {
                            Color.white
                            
                            // 3Dモデル表示
                            // ※ USDZViewer3Dの実装に合わせて引数を調整してください
                            USDZViewer3D(
                                origami.code + "3d" + String(stepnum),
                                width: geometry.size.width - 48, // 左右パディング分を引く
                                height: geometry.size.height * 0.8
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .frame(height: geometry.size.height * 0.8) // 画面の約55%
                        .cornerRadius(12)
                        .washiStyle() // 和紙風スタイル
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                        // ステップ番号バッジ
                        .overlay(alignment: .topTrailing) {
                            Text("STEP \(stepnum + 1) / \(origami.step)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 10)
                                .background(Color.themeIndigo)
                                .cornerRadius(8)
                                .padding(12)
                                .shadow(radius: 2)
                        }
                        
                        // 3. 説明テキストエリア
                            Text(currentStepText)
                                .font(.title2) // 少し大きめの文字で見やすく
                                .fontWeight(.medium)
                                .foregroundColor(.themeSumi)
                                .multilineTextAlignment(.center)
                                .padding()
                                .frame(maxWidth: .infinity)
                        .frame(maxHeight: 150)
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(8)
                        
                        Spacer()
                        
                        // 4. 操作ボタン（和風スタイル）
                        HStack(spacing: 20) {
                            // 戻るボタン
                            Button(action: {
                                if stepnum > 0 {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        stepnum -= 1
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text(languageManager.localizedString("Back"))
                                }
                                .font(.headline)
                                .foregroundColor(stepnum > 0 ? .white : .gray)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(stepnum > 0 ? Color.themeIndigo : Color.gray.opacity(0.3))
                                .cornerRadius(12)
                                .shadow(color: stepnum > 0 ? .themeIndigo.opacity(0.3) : .clear, radius: 4, y: 2)
                            }
                            .disabled(stepnum <= 0)
                            
                            // 進む / 完了ボタン
                            Button(action: {
                                if !isLastStep {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        stepnum += 1
                                    }
                                } else {
                                    navigationManager.navigate(to: .done(origami: origami))
                                }
                            }) {
                                HStack {
                                    Text(isLastStep ? languageManager.localizedString("complete") : languageManager.localizedString("Forward"))
                                    Image(systemName: isLastStep ? "checkmark.seal.fill" : "chevron.right")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(isLastStep ? Color.themeVermilion : Color.themeIndigo)
                                .cornerRadius(12)
                                .shadow(color: (isLastStep ? Color.themeVermilion : Color.themeIndigo).opacity(0.3), radius: 4, y: 2)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        // ツールバー設定
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { favoriteManager.toggleFavorite(origamiCode: origami.code) }) {
                    Image(systemName: favoriteManager.isFavorite(origamiCode: origami.code) ? "heart.fill" : "heart")
                        .resizable().frame(width: 30, height: 30)
                        .foregroundColor(favoriteManager.isFavorite(origamiCode: origami.code) ? .themeVermilion : .themeSumi)
                }
            }
            
            // チュートリアルボタン等が必要であれば追加
            /*
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { tutorialManager.startTutorial(for: .description3d, force: true) }) {
                    Image(systemName: "questionmark.circle")
                        .resizable().frame(width: 30, height: 30)
                        .foregroundColor(.themeIndigo)
                }
            }
            */
        }
    }
}
