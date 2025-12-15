import SwiftUI
import PhotosUI

struct SoundSettings: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var soundManager: SoundManager
    @State private var isShowingMusicPicker = false
    
    var body: some View {
        List {
            // 音量設定セクション
            Section {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text(languageManager.localizedString("volume"))
                                .font(.headline)
                            Spacer()
                            Text("\(Int(soundManager.volume * 100))%")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        
                        // 【修正】型推論エラーを防ぐため 0.0...1.0 と明示
                        Slider(value: $soundManager.volume, in: 0.0...1.0)
                            .accentColor(.blue)
                    }
                    .padding(.vertical, 10)
                }
            } header: {
                Text(languageManager.localizedString("volume_settings"))
                    .font(.headline)
            }
            
            // BGM設定セクション
            Section {
                HStack {
                    Image(systemName: soundManager.isBGMEnabled ? "music.note.circle.fill" : "music.note.circle")
                        .font(.title2)
                        .foregroundColor(.purple)
                    Text(languageManager.localizedString("bgm_enabled"))
                        .font(.body)
                    Spacer()
                    Toggle("", isOn: $soundManager.isBGMEnabled)
                        .labelsHidden()
                }
                .padding(.vertical, 5)
                
                if soundManager.isBGMEnabled {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("BGMタイプ")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Picker("BGM Type", selection: $soundManager.selectedBGMType) {
                            ForEach(BGMType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.vertical, 5)
                    
                    if soundManager.selectedBGMType == .custom {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("カスタムBGMリスト")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Button("音楽を追加") {
                                    isShowingMusicPicker = true
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            
                            if soundManager.customBGMUrls.isEmpty {
                                Text("カスタムBGMが登録されていません")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .italic()
                            } else {
                                ForEach(0..<soundManager.customBGMUrls.count, id: \.self) { index in
                                    HStack(spacing: 12) {
                                        Image(systemName: "music.note")
                                            .font(.caption)
                                            .foregroundColor(.purple)
                                            .frame(width: 16, height: 16)
                                        
                                        if index < soundManager.customBGMUrls.count {
                                            Text(soundManager.customBGMUrls[index].lastPathComponent)
                                                .font(.caption)
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            soundManager.removeCustomBGM(at: index)
                                        }) {
                                            Image(systemName: "trash")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                                .frame(width: 20, height: 20)
                                                .background(Color.clear)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                        .contentShape(Circle())
                                        // hoverEffectはiOS13.4+対応。エラーが出る場合は削除してください
                                        .hoverEffect(.highlight)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            
                            if !soundManager.customBGMUrls.isEmpty {
                                HStack {
                                    Image(systemName: "shuffle")
                                        .font(.caption)
                                        .foregroundColor(.purple)
                                    Text("ランダム再生")
                                        .font(.caption)
                                    Spacer()
                                    Toggle("", isOn: $soundManager.isShuffleEnabled)
                                        .labelsHidden()
                                        .scaleEffect(0.8)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
            } header: {
                Text(languageManager.localizedString("bgm_settings"))
                    .font(.headline)
            }
            
            Section {
                Button(action: {
                    soundManager.resetToDefaults()
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text(languageManager.localizedString("reset_sound_settings"))
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                }
                .padding(.vertical, 5)
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
}
