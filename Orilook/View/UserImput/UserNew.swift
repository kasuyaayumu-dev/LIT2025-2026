import SwiftUI

struct UserNew: View {
    // ✅ indexを削除し、編集モードを追加
    let editingOrigamiCode: String? // 既存作品を編集する場合
    
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var imageManager: ImageManager
    @EnvironmentObject var userOrigamiManager: UserOrigamiManager
    
    // 編集用の状態
    @State private var origamiName: String = ""
    @State private var selectedImage: UIImage?
    @State private var showingPhotoPickerSheet = false
    @State private var isEditingName = false
    @State private var difficulty: Int = 1
    @State private var selectedTags: Set<String> = []
    
    // 機能フラグ（元のUIに合わせて非表示）
    @State private var step = 1
    @State private var hasFold = true
    @State private var hasOpen = true
    @State private var has3D = true
    @State private var hasAR = true
    
    init(editingOrigamiCode: String? = nil) {
        self.editingOrigamiCode = editingOrigamiCode
    }
    
    var body: some View {
        VStack(spacing: 25) {
            // 作品名ボタン（元のUIを維持）
            Button(action: {
                isEditingName = true
            }) {
                HStack {
                    Image(systemName: "pencil.line")
                        .resizable()
                        .scaledToFit()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.black)
                    Text(origamiName.isEmpty ? "作品名" : origamiName)
                        .font(.system(size: 50))
                        .foregroundColor(.black)
                }
            }
            
            // 画像表示エリア
            ZStack {
                if let image = selectedImage {
                    // 画像が選択されている場合
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    // 画像が未選択の場合：グレー背景＋カメラアイコン
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(4/3, contentMode: .fit)
                        .overlay(
                            Image(systemName: "camera")
                                .font(.system(size: 80))
                                .foregroundColor(.gray)
                        )
                }
            }
            
            // 画像追加/変更ボタン
            Button(action: {
                showingPhotoPickerSheet = true
            }) {
                HStack {
                    Color.clear
                        .frame(maxWidth: 50, maxHeight: 3)
                    Text(selectedImage == nil ? "画像を追加" : "画像を変更")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(.blue)
                        .clipShape(.capsule)
                        .shadow(color: Color.cyan, radius: 15, x: 0, y: 5)
                    Spacer()
                }
            }
            
            Text("編集したい項目を選択してください")
                .font(.system(size: 40))
            
            // 画面サイズ対応のモード選択ボタン（元のUIを維持）
            GeometryReader { geometry in
                let buttonWidth = min(300, (geometry.size.width - 120) / 2)
                let spacing: CGFloat = 40
                
                VStack(spacing: spacing) {
                    HStack(spacing: spacing) {
                        Button(action: {
                            // 2D解説追加（将来実装）
                        }) {
                            Text("2D解説追加")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: buttonWidth, height: 150)
                                .background(.blue)
                                .clipShape(.capsule)
                                .shadow(color: Color.cyan, radius: 15, x: 0, y: 5)
                        }
                        
                        Button(action: {
                            // 展開図追加（将来実装）
                        }) {
                            Text("展開図追加")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: buttonWidth, height: 150)
                                .background(.blue)
                                .clipShape(.capsule)
                                .shadow(color: Color.cyan, radius: 15, x: 0, y: 5)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    HStack(spacing: spacing) {
                        // 作品詳細設定へのNavigationLink
                        NavigationLink(destination: UserDetailSettings(
                            step: $step,
                            difficulty: $difficulty,
                            selectedTags: $selectedTags,
                            hasFold: $hasFold,
                            hasOpen: $hasOpen,
                            has3D: $has3D,
                            hasAR: $hasAR
                        )) {
                            Text("作品詳細設定")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: buttonWidth, height: 150)
                                .background(.blue)
                                .clipShape(.capsule)
                                .shadow(color: Color.cyan, radius: 15, x: 0, y: 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            // 3D解説追加（将来実装）
                        }) {
                            Text("3D解説追加")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: buttonWidth, height: 150)
                                .background(.blue)
                                .clipShape(.capsule)
                                .shadow(color: Color.cyan, radius: 15, x: 0, y: 5)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 340)
            
            // ✅ 保存ボタンを追加
            Button(action: {
                saveOrigami()
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                    Text("作品を保存")
                        .font(.system(size: 24))
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(canSave ? Color.green : Color.gray)
                .cornerRadius(12)
                .shadow(color: canSave ? .green.opacity(0.5) : .gray.opacity(0.5), radius: 15, x: 0, y: 5)
            }
            .disabled(!canSave)
            .padding(.horizontal, 40)
        }
        .navigationTitle(languageManager.localizedString("select_mode_title"))
        .toolbar {
            HStack {
                // 設定ギアアイコン
                Button(action: {
                    navigationManager.navigate(to: .settings)
                }) {
                    VStack {
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.black)
                    }
                }
            }
        }
        .onAppear {
            loadOrigamiData()
        }
        .sheet(isPresented: $showingPhotoPickerSheet) {
            PhotoPickerSheet(
                selectedImage: $selectedImage,
                isPresented: $showingPhotoPickerSheet
            )
        }
        .sheet(isPresented: $isEditingName) {
            // 作品名編集シート
            NavigationView {
                VStack(spacing: 20) {
                    Text("作品名を入力")
                        .font(.headline)
                        .padding(.top, 20)
                    
                    TextField("作品名", text: $origamiName)
                        .font(.system(size: 24))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 32)
                    
                    Spacer()
                    
                    Button(action: {
                        isEditingName = false
                    }) {
                        Text("完了")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                }
                .navigationTitle("作品名")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("閉じる") {
                            isEditingName = false
                        }
                    }
                }
            }
            .presentationDetents([.height(250)])
        }
    }
    
    // MARK: - Computed Properties
    
    private var canSave: Bool {
        !origamiName.trimmingCharacters(in: .whitespaces).isEmpty && selectedImage != nil
    }
    
    // MARK: - Functions
    
    private func loadOrigamiData() {
        // 既存作品を編集する場合
        if let code = editingOrigamiCode,
           let origami = userOrigamiManager.getOrigami(code: code) {
            origamiName = origami.name
            step = origami.step
            difficulty = origami.dif
            selectedTags = Set(origami.tag)
            hasFold = origami.fold
            hasOpen = origami.open
            has3D = origami.threed
            hasAR = origami.AR
            
            // 画像を読み込み
            if let image = imageManager.getImage(for: origami.code) {
                selectedImage = image
            }
        } else {
            // 新規作成の場合はデフォルト値
            origamiName = ""
            step = 1
            difficulty = 1
            selectedTags = ["simple"] // デフォルトタグ
            hasFold = true
            hasOpen = true
            has3D = true
            hasAR = true
        }
    }
    
    private func saveOrigami() {
        guard canSave, let image = selectedImage else { return }
        
        let newOrigami = OrigamiController(
            code: editingOrigamiCode ?? "user_\(UUID().uuidString)",
            name: origamiName,
            step: step, // ✅ 詳細設定で設定した値を使用
            dif: difficulty,
            text: Array(repeating: "この作品の説明", count: step), // ✅ stepの数だけテキストを生成
            tag: Array(selectedTags),
            fold: hasFold,
            open: hasOpen,
            threed: has3D,
            AR: hasAR
        )
        
        // 画像を保存
        imageManager.saveUserImage(image, for: newOrigami.code)
        
        // 作品を保存
        if editingOrigamiCode != nil {
            userOrigamiManager.updateOrigami(newOrigami)
        } else {
            userOrigamiManager.addOrigami(newOrigami)
        }
        
        // リストに戻る
        navigationManager.popToRoot()
    }
}

#Preview {
    NavigationStack {
        UserNew()
    }
    .environmentObject(LanguageManager())
    .environmentObject(NavigationManager())
    .environmentObject(ImageManager())
    .environmentObject(UserOrigamiManager())
}
