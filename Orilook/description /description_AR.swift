import SwiftUI
import ARKit
import RealityKit
import AVFoundation

struct description_AR: View {
    let origami: OrigamiController
    
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var favoriteManager: FavoriteManager
    // @EnvironmentObject var tutorialManager: TutorialManager // チュートリアル実装時にコメントアウト解除
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
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // MARK: 1. 最背面：ARビュー（画面全体）
                PersistentARUSDZViewer(
                    fileName: currentModelName,
                    width: geometry.size.width,
                    height: geometry.size.height
                )
                .ignoresSafeArea()
                
                // MARK: 2. UIオーバーレイ層
                VStack {
                    // --- 上部浮遊パネル（戻るボタンとステップ表示）---
                    HStack {
                        // カスタム戻るボタン
                        Button(action: handleBackNavigation) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .fontWeight(.semibold)
                                Text(languageManager.localizedString("Back"))
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.themeIndigo)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.themeWashi.opacity(0.9))
                            .cornerRadius(8)
                        }
                        Spacer()
                        
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
                            .foregroundColor(.themeIndigo)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(Color.themeWashi.opacity(0.7))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        // ステップ表示バッジ
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
                    .padding(.horizontal)
                    .padding(.top, geometry.safeAreaInsets.top > 0 ? geometry.safeAreaInsets.top : 16)
                    
                    Spacer()
                    
                    // --- 下部浮遊パネル（説明と操作ボタン）---
                    VStack(spacing: 20) {
                        // ガイドメッセージ
                        Text(languageManager.localizedString("tap_to_place"))
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(12)
                        
                        // メイン操作パネル（和紙風）
                        VStack(spacing: 24) {
                            // 説明テキスト
                            ScrollView {
                                Text(currentStepText)
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.themeSumi)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                            }
                            .frame(maxHeight: 100)
                            
                            // 操作ボタン群
                            HStack(spacing: 16) {
                                // 前へボタン
                                ARNavigationButton(
                                    title: languageManager.localizedString("Back"),
                                    icon: "chevron.left",
                                    isEnabled: stepnum > 0,
                                    isPrimary: false,
                                    action: {
                                        if stepnum > 0 { withAnimation { stepnum -= 1 } }
                                    }
                                )
                                
                                // 次へ / 完了ボタン
                                ARNavigationButton(
                                    title: isLastStep ? languageManager.localizedString("Done") : languageManager.localizedString("Forward"),
                                    icon: isLastStep ? "checkmark" : "chevron.right",
                                    isEnabled: true,
                                    isPrimary: true,
                                    isLastStep: isLastStep,
                                    action: {
                                        if !isLastStep {
                                            withAnimation { stepnum += 1 }
                                        } else {
                                            handleCompletion()
                                        }
                                    }
                                )
                            }
                        }
                        .padding(24)
                        .background(Color.themeWashi)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom : 24)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            requestCameraPermissionIfNeeded()
        }
        .alert("カメラアクセス", isPresented: $showPermissionAlert) {
            Button("設定を開く", action: openSettings)
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("AR機能を使用するにはカメラへのアクセス許可が必要です。")
        }
    }
    
    // MARK: - UI Components
    
    // AR用のナビゲーションボタンコンポーネント
    private func ARNavigationButton(title: String, icon: String, isEnabled: Bool, isPrimary: Bool, isLastStep: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                if !isPrimary { Image(systemName: icon) }
                Text(title).fontWeight(.bold)
                if isPrimary { Image(systemName: icon) }
            }
            .font(.headline)
            .foregroundColor(isEnabled ? .white : .gray.opacity(0.8))
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                isEnabled ? (isLastStep ? Color.themeVermilion : Color.themeIndigo) : Color.gray.opacity(0.3)
            )
            .cornerRadius(12)
            // 修正箇所: 型推論エラーを防ぐため Color.themeVermilion, Color.themeIndigo と明示的に記述
            .shadow(color: isEnabled ? (isLastStep ? Color.themeVermilion : Color.themeIndigo).opacity(0.3) : .clear, radius: 4, y: 2)
        }
        .disabled(!isEnabled)
    }
    
    // MARK: - Logic Methods
    private func handleBackNavigation() {
        clearARData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismiss()
        }
    }
    
    private func handleCompletion() {
        clearARData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            navigationManager.navigate(to: .done(origami: origami))
        }
    }
    
    private func clearARData() {
        arStateManager.clearAllModelPlacements()
        arStateManager.resetTrigger = UUID()
    }
    
    private func requestCameraPermissionIfNeeded() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if !granted {
                        showPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert = true
        case .authorized:
            break
        @unknown default:
            break
        }
    }
    
    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}
