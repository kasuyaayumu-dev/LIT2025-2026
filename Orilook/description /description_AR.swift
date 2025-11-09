import SwiftUI
import ARKit
import RealityKit
import AVFoundation

struct description_AR: View {
    let index: Int
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var navigationManager: NavigationManager
    @State var stepnum = 0
    @State private var showPermissionAlert = false
    @ObservedObject private var arStateManager = ARStateManager.shared
    @State private var currentModelName: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text(getOrigamiArray(languageManager: languageManager)[index].name)
                .font(.system(size: 32))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            PersistentARUSDZViewer(
                fileName: getOrigamiArray(languageManager: languageManager)[index].code + "3d" + String(stepnum),
                width: 550,
                height: 600
            )
            
            Text(languageManager.localizedString("tap_to_place"))
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView {
                Text(getOrigamiArray(languageManager: languageManager)[index].text[stepnum])
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
            .padding(.bottom)
        }
        .onAppear {
            requestCameraPermissionIfNeeded()
            currentModelName = getOrigamiArray(languageManager: languageManager)[index].code + "3d" + String(stepnum)
        }
        .onChange(of: stepnum) { _ in
            let newModelName = getOrigamiArray(languageManager: languageManager)[index].code + "3d" + String(stepnum)
            if newModelName != currentModelName {
                currentModelName = newModelName
                print("ステップ変更: \(currentModelName)")
            }
        }
        .onDisappear {
            // 画面を離れる際にワールドマップを保存
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
