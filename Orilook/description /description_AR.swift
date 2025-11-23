import SwiftUI
import ARKit
import RealityKit
import AVFoundation

struct description_AR: View {
    let index: Int
    
    // --- Environment / State ---
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var navigationManager: NavigationManager
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
            Text(origamiItem.name) // 整理したプロパティを使用
                        .font(.system(size: 32))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    PersistentARUSDZViewer(
                        fileName: currentModelName, // 整理したプロパティを使用
                        width: 550,
                        height: 600
                    )
                    
                    Text(languageManager.localizedString("tap_to_place"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        Text(currentStepText) // 整理したプロパティを使用
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
                                // 最後のステップなら完了画面へ
                                navigationManager.navigate(to: .done(index: index))
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
                .onAppear {
                    requestCameraPermissionIfNeeded()
                    // `.onChange` があるので、ここで `currentModelName` を設定する必要はなくなります
                }
                .onChange(of: stepnum) { _ in
                    // このViewでは `currentModelName` は `stepnum` から自動計算されるので、
                    // `.onChange` での同期処理は不要かもしれません。
                    // もし `PersistentARUSDZViewer` がファイル名変更を検知するために必要なら残します。
                    print("ステップ変更: \(currentModelName)")
                }
                .onDisappear {
                    print("AR画面を離れます - 状態を保持")
                }
                .alert("カメラアクセス", isPresented: $showPermissionAlert) {
                    Button("設定を開く", action: openSettings)
                    Button("キャンセル", role: .cancel) { }
                } message: {
                    Text("AR機能を使用するにはカメラへのアクセス許可が必要です。")
                }
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
