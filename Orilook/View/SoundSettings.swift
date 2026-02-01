import SwiftUI
import PhotosUI

struct SoundSettings: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var soundManager: SoundManager
    @State private var isShowingMusicPicker = false
    
    var body: some View {
        ZStack {
            // 背景：生成り色
            Color.themeWashi.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - 音量設定
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: languageManager.localizedString("volume_settings"))
                        
                        VStack(spacing: 20) {
                            HStack {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.title2)
                                    .foregroundColor(.themeIndigo)
                                Text(languageManager.localizedString("volume"))
                                    .font(.headline)
                                    .foregroundColor(.themeSumi)
                                Spacer()
                                Text("\(Int(soundManager.volume * 100))%")
                                    .font(.title3)
                                    .fontWeight(.bold) // 数字は太くしてモダンに
                                    .foregroundColor(.themeIndigo)
                                    .monospacedDigit() // 数字の幅を等しく
                            }
                            
                            Slider(value: $soundManager.volume, in: 0.0...1.0)
                                .accentColor(.themeIndigo) // スライダーの色変更
                        }
                        .padding(20)
                        .washiStyle()
                    }
                    
                    // MARK: - BGM設定
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: languageManager.localizedString("bgm_settings"))
                        
                        VStack(spacing: 0) {
                            // BGM ON/OFF
                            HStack {
                                Image(systemName: soundManager.isBGMEnabled ? "music.note.circle.fill" : "music.note.circle")
                                    .font(.title2)
                                    .foregroundColor(soundManager.isBGMEnabled ? .themeIndigo : .gray)
                                Text(languageManager.localizedString("bgm_enabled"))
                                    .font(.body)
                                    .foregroundColor(.themeSumi)
                                Spacer()
                                Toggle("", isOn: $soundManager.isBGMEnabled)
                                    .labelsHidden()
                                    .tint(.themeIndigo) // トグルの色変更
                            }
                            .padding(20)
                            
                            if soundManager.isBGMEnabled {
                                Divider().background(Color.themeSumi.opacity(0.1))
                                
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("BGMタイプ")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Picker("BGM Type", selection: $soundManager.selectedBGMType) {
                                        ForEach(BGMType.allCases, id: \.self) { type in
                                            Text(type.displayName).tag(type)
                                        }
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    .colorMultiply(.themeWashi) // ピッカーの背景を少し馴染ませる（完全な制御は難しいですが）
                                    
                                    // カスタムBGM設定エリア
                                    if soundManager.selectedBGMType == .custom {
                                        customBGMListArea()
                                    }
                                }
                                .padding(20)
                                .background(Color.themeWashi.opacity(0.5)) // 内部エリアを少し暗く
                            }
                        }
                        .washiStyle()
                    }
                    
                    // MARK: - リセットボタン
                    Button(action: {
                        soundManager.resetToDefaults()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.title2)
                            Text(languageManager.localizedString("reset_sound_settings"))
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .foregroundColor(.themeVermilion) // 朱色
                        .padding(20)
                        .washiStyle()
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle(languageManager.localizedString("sound_settings_title"))
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            if soundManager.selectedBGMType == .custom && soundManager.customBGMUrls.isEmpty {
                print("No custom music found on exit. Reverting to default.")
                soundManager.selectedBGMType = .defaultBGM
                if soundManager.isBGMEnabled {
                    soundManager.playBackgroundMusic()
                }
            }
        }
        .fileImporter(
            isPresented: $isShowingMusicPicker,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    soundManager.addCustomBGM(url: url)
                }
                if !urls.isEmpty {
                    DispatchQueue.main.async {
                        if soundManager.selectedBGMType != .custom {
                            soundManager.selectedBGMType = .custom
                        }
                        if soundManager.isBGMEnabled {
                            soundManager.playBackgroundMusic()
                        }
                    }
                }
            case .failure(let error):
                print("Failed to import music: \(error)")
            }
        }
    }
    
    // カスタムBGM部分のサブビュー切り出し
    private func customBGMListArea() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("カスタムBGMリスト")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.themeSumi)
                Spacer()
                Button(action: { isShowingMusicPicker = true }) {
                    Label("追加", systemImage: "plus")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.themeIndigo)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            
            if soundManager.customBGMUrls.isEmpty {
                Text("カスタムBGMが登録されていません")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 10)
            } else {
                ForEach(0..<soundManager.customBGMUrls.count, id: \.self) { index in
                    HStack(spacing: 12) {
                        Image(systemName: "music.note")
                            .font(.caption)
                            .foregroundColor(.themeIndigo)
                        
                        if index < soundManager.customBGMUrls.count {
                            Text(soundManager.customBGMUrls[index].lastPathComponent)
                                .font(.caption)
                                .foregroundColor(.themeSumi)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            soundManager.removeCustomBGM(at: index)
                        }) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(.themeVermilion)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.white)
                    .cornerRadius(4)
                }
            }
            
            if !soundManager.customBGMUrls.isEmpty {
                HStack {
                    Image(systemName: "shuffle")
                        .font(.caption)
                        .foregroundColor(.themeIndigo)
                    Text("ランダム再生")
                        .font(.caption)
                        .foregroundColor(.themeSumi)
                    Spacer()
                    Toggle("", isOn: $soundManager.isShuffleEnabled)
                        .labelsHidden()
                        .scaleEffect(0.8)
                        .tint(.themeIndigo)
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.03)) // 薄いグレーの背景
        .cornerRadius(6)
    }
}

// セクションヘッダー用ビュー
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.gray)
            .padding(.leading, 4)
    }
}
