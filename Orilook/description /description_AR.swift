import SwiftUI
import ARKit
import RealityKit
import AVFoundation

struct description_AR: View {
    let origami: OrigamiController
    
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var favoriteManager: FavoriteManager
    @EnvironmentObject var tutorialManager: TutorialManager
    @Environment(\.dismiss) private var dismiss
    
    @State var stepnum = 0
    @State private var showPermissionAlert = false
    @ObservedObject private var arStateManager = ARStateManager.shared
    
    // MARK: - Computed Properties
    private var modelNameList: [String] {
        (0..<origami.step).map { origami.code + "3d" + String($0) }
    }
    
    private var currentModelName: String {
        stepnum < modelNameList.count ? modelNameList[stepnum] : ""
    }
    
    private var currentStepText: String {
        stepnum < origami.text.count ? origami.text[stepnum] : ""
    }
    
    private var isLastStep: Bool {
        stepnum == origami.step - 1
    }
    
    var body: some View {
        ZStack {
            // 1. 最背面：ARビュー（画面全体）
            PersistentARUSDZViewer(
                fileName: currentModelName,
                width: UIScreen.main.bounds.width,
                height: UIScreen.main.bounds.height
            )
            .ignoresSafeArea()
            
            // 2. UIオーバーレイ層
            VStack {
                // 上部：ステップ表示（浮遊バッジ）
                HStack {
                    Spacer()
                    Text("STEP \(stepnum + 1) / \(origami.step)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.themeIndigo)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        .padding(.top, 10)
                    Spacer()
                }
                
                Spacer()
                
                // 下部：操作パネル（和紙風カード）
                VStack(spacing: 20) {
                    // ガイドメッセージ
                    Text(languageManager.localizedString("tap_to_place"))
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                    
                    // カードパネル
                    VStack(spacing: 24) {
                        // 説明テキスト
                        ScrollView {
                            Text(currentStepText)
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.themeSumi)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)
                        }
                        .frame(maxHeight: 80)
                        
                        // 操作ボタン群
                        HStack(spacing: 16) {
                            // 戻る（ステップ）
                            Button(action: {
                                if stepnum > 0 { withAnimation { stepnum -= 1 } }
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
                            
                            // 進む / 完了
                            Button(action: {
                                if !isLastStep {
                                    withAnimation { stepnum += 1 }
                                } else {
                                    handleCompletion()
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
                    }
                    .padding(24)
                    .background(Color.themeWashi) // 和紙背景
                    .cornerRadius(16)
                    .washiStyle() // 和紙風スタイル適用
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // 左：戻るボタン（他のDescription画面と統一）
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { handleBackNavigation() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                    }
                    .foregroundColor(Color.black.opacity(0.8))
                    .padding(6)
                    .cornerRadius(8)
                }
            }
            
            // 右：お気に入り
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { favoriteManager.toggleFavorite(origamiCode: origami.code) }) {
                    Image(systemName: favoriteManager.isFavorite(origamiCode: origami.code) ? "heart.fill" : "heart")
                        .resizable().frame(width: 30, height: 30)
                        .foregroundColor(favoriteManager.isFavorite(origamiCode: origami.code) ? .themeVermilion : .themeSumi)
                }
            }
            
//             チュートリアルボタン等が必要であれば追加
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { tutorialManager.startTutorial(for: .description3d, force: true) }) {
                    Image(systemName: "questionmark.circle")
                        .resizable().frame(width: 30, height: 30)
                        .foregroundColor(.themeIndigo)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    navigationManager.navigate(to: .settings)
                }) {
                    Image(systemName: "gearshape.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.themeSumi)
                }
            }
        }
        .onAppear {
            requestCameraPermissionIfNeeded()
        }
        .alert("カメラアクセス", isPresented: $showPermissionAlert) {
            Button("設定を開く", action: openSettings)
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("AR機能を使用するにはカメラへのアクセス許可が必要です。")
        }
        .tutorial(flow: .descriptionAR, autoStart: true)
    }
    
    // MARK: - Logic Methods
    private func handleBackNavigation() {
        clearARData()
        dismiss()
    }
    
    private func handleCompletion() {
        clearARData()
        navigationManager.navigate(to: .done(origami: origami))
    }
    
    private func clearARData() {
        arStateManager.clearAllModelPlacements()
        arStateManager.resetTrigger = UUID()
    }
    
    private func requestCameraPermissionIfNeeded() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { if !granted { showPermissionAlert = true } }
            }
        } else if status == .denied || status == .restricted {
            showPermissionAlert = true
        }
    }
    
    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}
