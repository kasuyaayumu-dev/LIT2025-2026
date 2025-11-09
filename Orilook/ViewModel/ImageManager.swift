import SwiftUI
import UIKit
import PhotosUI

class ImageManager: ObservableObject {
    @Published var userImages: [String: UIImage] = [:]
    private let userDefaultsKey = "userImagesData"
    
    init() {
        loadUserImages()
    }
    
    // ユーザーが撮影/選択した画像を保存
    func saveUserImage(_ image: UIImage, for origamiCode: String) {
        userImages[origamiCode] = image
        saveUserImagesToUserDefaults()
    }
    
    // 指定された折り紙コードの画像を取得（ユーザー画像が優先）
    func getImage(for origamiCode: String) -> UIImage? {
        return userImages[origamiCode]
    }
    
    // ユーザー画像があるかチェック
    func hasUserImage(for origamiCode: String) -> Bool {
        return userImages[origamiCode] != nil
    }
    
    // ユーザー画像を削除
    func removeUserImage(for origamiCode: String) {
        userImages.removeValue(forKey: origamiCode)
        saveUserImagesToUserDefaults()
    }
    
    // 全てのユーザー画像を削除
    func removeAllUserImages() {
        userImages.removeAll()
        saveUserImagesToUserDefaults()
    }
    
    // UserDefaultsに保存
    private func saveUserImagesToUserDefaults() {
        let imageData = userImages.compactMapValues { image in
            image.jpegData(compressionQuality: 0.8)
        }
        
        if let encoded = try? JSONEncoder().encode(imageData) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    // UserDefaultsから読み込み
    private func loadUserImages() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([String: Data].self, from: data) else {
            return
        }
        
        userImages = decoded.compactMapValues { data in
            UIImage(data: data)
        }
    }
}

// モダンなPHPickerViewController用
struct PhotoPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider else {
                parent.dismiss()
                return
            }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                        self.parent.dismiss()
                    }
                }
            } else {
                parent.dismiss()
            }
        }
    }
}

// カメラ用のImagePicker
struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        
        init(_ parent: CameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}