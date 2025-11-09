import SwiftUI
import AVFoundation
import UIKit

struct PhotoPickerSheet: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    @State private var showingPhotoPicker = false
    @State private var showingCamera = false
    @State private var cameraPermissionStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var isCameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ハンドルバー
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray3))
                    .frame(width: 40, height: 6)
                    .padding(.top, 8)
                
                // タイトル
                VStack(spacing: 16) {
                    Text(languageManager.localizedString("select_source"))
                        .font(.headline)
                        .padding(.top, 20)
                    
                    VStack(spacing: 12) {
                        // フォトライブラリボタン
                        Button(action: {
                            showingPhotoPicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                    .frame(width: 30)
                                
                                Text(languageManager.localizedString("photo_library"))
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                        
                        // カメラボタン
                        if isCameraAvailable {
                            Button(action: {
                                if cameraPermissionStatus == .authorized {
                                    showingCamera = true
                                } else {
                                    requestCameraPermission()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "camera")
                                        .font(.title2)
                                        .foregroundColor(cameraPermissionStatus == .denied ? .gray : .blue)
                                        .frame(width: 30)
                                    
                                    Text(languageManager.localizedString("camera"))
                                        .font(.body)
                                        .foregroundColor(cameraPermissionStatus == .denied ? .secondary : .primary)
                                    
                                    Spacer()
                                    
                                    if cameraPermissionStatus == .denied {
                                        Text("許可が必要")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                            }
                            .disabled(cameraPermissionStatus == .denied)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // キャンセルボタン
                    Button(action: {
                        isPresented = false
                    }) {
                        Text(languageManager.localizedString("cancel"))
                            .font(.body)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPicker(selectedImage: $selectedImage)
                .onDisappear {
                    if selectedImage != nil {
                        isPresented = false
                    }
                }
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker(selectedImage: $selectedImage)
                .onDisappear {
                    if selectedImage != nil {
                        isPresented = false
                    }
                }
        }
        .onAppear {
            cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
            isCameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        }
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
                if granted {
                    showingCamera = true
                }
            }
        }
    }
}

#Preview {
    PhotoPickerSheet(
        selectedImage: .constant(nil),
        isPresented: .constant(true)
    )
    .environmentObject(LanguageManager())
}