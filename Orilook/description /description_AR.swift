import SwiftUI
import ARKit
import RealityKit
import AVFoundation

struct description_AR: View {
    let index: Int
    
    // --- Environment / State ---
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(\.dismiss) private var dismiss // ✅ 標準の戻る処理用
    @State var stepnum = 0 // 現在のステップ番号
    
    @State private var showPermissionAlert = false
    @ObservedObject private var arStateManager = ARStateManager.shared
    
    // --- 1. コンピューテッドプロパティでデータを整理 ---
    
    /// 現在表示している折り紙のデータ
    private var origamiItem: OrigamiController {
        getOrigamiArray(languageManager: languageManager)[index]
    }
    
    /// 3Dモデル名の全ステップのリスト (例: ["fortune3d0", "fortune3d1", ...])
    private var modelNameList: [String] {
        (0..<origamiItem.step).map { stepnum in
            origamiItem.code + "3d" + String(stepnum)
        }
    }
    
    /// 現在のステップの3Dモデル名
    private var currentModelName: String {
        modelNameList[stepnum] // listから現在のステップ番号で取り出す
    }
    
    /// 現在のステップの解説文
    private var currentStepText: String {
        origamiItem.text[stepnum]
    }
    
    /// ステップの総数
    private var totalSteps: Int {
        origamiItem.step
    }
    
    /// 最後のステップかどうか
    private var isLastStep: Bool {
        stepnum == totalSteps - 1
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text(origamiItem.name)
                .font(.system(size: 32))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            PersistentARUSDZViewer(
                fileName: currentModelName,
                width: 550,
                height: 600
            )
            
            Text(languageManager.localizedString("tap_to_place"))
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView {
                Text(currentStepText)
                    .padding()
                    .multilineTextAlignment(.center)
                    .font(.system(size: 30))
            }
            .frame(maxHeight: 80)
            
            HStack(spacing: 40) {
                // 「戻る」ボタン
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
                
                // 「次へ」/「完了」ボタン
                Button {
                    if !isLastStep {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            stepnum += 1
                        }
                    } else {
                        // ✅ 最後のステップなら完了処理を実行
                        handleCompletion()
                    }
                } label: {
                    Text(isLastStep ? languageManager.localizedString("Done") : languageManager.localizedString("Forward"))
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 100)
                        .background(isLastStep ? .yellow : .red)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .shadow(color: isLastStep ? .gray : .pink, radius: 15, x: 0, y: 5)
                }
            }
            .padding(.bottom)
        }
        .navigationBarBackButtonHidden(true) // ✅ デフォルトの戻るボタンを非表示
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                // ✅ カスタム戻るボタン
                Button(action: {
                    handleBackNavigation()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                        Text(languageManager.localizedString("select_mode_title"))
                            .font(.system(size: 17))
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            requestCameraPermissionIfNeeded()
            print("AR画面表示: \(currentModelName)")
        }
        .onChange(of: stepnum) { oldValue, newValue in
            print("ステップ変更: \(oldValue) -> \(newValue), モデル: \(currentModelName)")
        }
        .onDisappear {
            print("AR画面を離れます")
        }
        .alert("カメラアクセス", isPresented: $showPermissionAlert) {
            Button("設定を開く", action: openSettings)
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("AR機能を使用するにはカメラへのアクセス許可が必要です。")
        }
    }
    
    // ✅ 標準の戻るボタンをタップした時の処理
    private func handleBackNavigation() {
        print("戻るボタン: ARデータをクリア")
        
        // ARデータをクリア
        clearARData()
        
        // 少し待ってから前の画面に戻る
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss() // ✅ SwiftUI標準の戻る処理
        }
    }
    
    // ✅ 完了処理(ARデータをクリアしてから完了画面へ)
    private func handleCompletion() {
        print("完了処理: ARデータをクリア")
        
        // ARデータをクリア
        clearARData()
        
        // 少し待ってから完了画面へ遷移
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            navigationManager.navigate(to: .done(index: index))
        }
    }
    
    // ✅ ARデータクリア処理を共通化
    private func clearARData() {
        // 1. ARStateManagerの全データをクリア
        arStateManager.clearAllModelPlacements()
        
        // 2. リセットトリガーを発動してCoordinatorにアンカー削除を指示
        arStateManager.resetTrigger = UUID()
        
        print("✅ ARデータクリア完了")
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
