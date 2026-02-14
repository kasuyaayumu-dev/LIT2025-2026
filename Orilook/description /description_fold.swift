import SwiftUI

struct description_fold: View {
    let origami: OrigamiController
    
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var imageManager: ImageManager
    @EnvironmentObject var completionManager: CompletionManager
    @EnvironmentObject var favoriteManager: FavoriteManager
    @EnvironmentObject var tutorialManager: TutorialManager
    @State private var showingPhotoPickerSheet = false
    @State private var selectedImage: UIImage?
    
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
                    
                    Text(languageManager.localizedString("fold"))
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                // メインコンテンツエリア
                GeometryReader { geometry in
                    VStack(spacing: 24) {
                        
                        // 2. 折り図画像エリア（額装風）
                        ZStack {
                            Color.white
                            
                            // 画像表示
                            Image(origami.code + "2d" + String(stepnum))
                                .resizable()
                                .scaledToFit()
                                .padding(20) // 画像周りの余白
                        }
                        .frame(height: geometry.size.height * 0.8) // 画面の約半分を画像エリアに
                        .cornerRadius(12)
                        .washiStyle() // 和紙風スタイル（影など）
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
                            .font(.title2)
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
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { tutorialManager.startTutorial(for: .descriptionFold, force: true) }) {
                    Image(systemName: "questionmark.circle")
                        .resizable().frame(width: 30, height: 30)
                        .foregroundColor(.themeIndigo)
                }
            }
        }
        .sheet(isPresented: $showingPhotoPickerSheet) {
            PhotoPickerSheet(
                selectedImage: $selectedImage,
                isPresented: $showingPhotoPickerSheet
            )
        }
        .tutorial(flow: .descriptionFold, autoStart: true)
    }
}
