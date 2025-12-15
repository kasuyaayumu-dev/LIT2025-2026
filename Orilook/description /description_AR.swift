import SwiftUI
import ARKit
import RealityKit
import AVFoundation

struct description_AR: View {
    // 【修正】IntではなくOrigamiControllerを受け取る
    let origami: OrigamiController
    
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(\.dismiss) private var dismiss
    @State var stepnum = 0
    
    @State private var showPermissionAlert = false
    @ObservedObject private var arStateManager = ARStateManager.shared
    
    private var modelNameList: [String] {
        (0..<origami.step).map { stepnum in
            origami.code + "3d" + String(stepnum)
        }
    }
    
    private var currentModelName: String {
        if stepnum < modelNameList.count {
            return modelNameList[stepnum]
        }
        return ""
    }
    
    private var currentStepText: String {
        if stepnum < origami.text.count {
            return origami.text[stepnum]
        }
        return ""
    }
    
    private var totalSteps: Int {
        origami.step
    }
    
    private var isLastStep: Bool {
        stepnum == totalSteps - 1
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text(origami.name)
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
                    if !isLastStep {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            stepnum += 1
                        }
                    } else {
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
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
        }
        .alert("カメラアクセス", isPresented: $showPermissionAlert) {
            Button("設定を開く", action: openSettings)
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("AR機能を使用するにはカメラへのアクセス許可が必要です。")
        }
    }
    
    private func handleBackNavigation() {
        clearARData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
    
    private func handleCompletion() {
        clearARData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // 【修正】ここがエラーの原因でした。origamiを渡すように修正済み
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
