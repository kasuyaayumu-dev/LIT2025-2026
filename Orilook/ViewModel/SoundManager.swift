import SwiftUI
import AVFoundation
import MediaPlayer
import UIKit

enum BGMType: String, CaseIterable {
    case defaultBGM = "default"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .defaultBGM: return "Default BGM"
        case .custom: return "Custom Music"
        }
    }
}

class SoundManager: NSObject, ObservableObject {
    @Published var volume: Double = 0.5 {
        didSet {
            saveVolume()
            updateVolume()
        }
    }
    
    @Published var isBGMEnabled: Bool = true {
        didSet {
            saveBGMEnabled()
            if isBGMEnabled {
                playBackgroundMusic()
            } else {
                stopBackgroundMusic()
            }
        }
    }
    
    @Published var selectedBGMType: BGMType = .defaultBGM {
        didSet {
            saveBGMType()
            if isBGMEnabled {
                // 即座に新しいBGMタイプに切り替える
                stopBackgroundMusic()
                playBackgroundMusic()
            }
        }
    }
    
    @Published var customBGMUrls: [URL] = [] {
        didSet {
            saveCustomBGMUrls()
            if selectedBGMType == .custom && isBGMEnabled {
                // カスタムBGMリストが変更された場合は即座に新しいリストから再生
                stopBackgroundMusic()
                playBackgroundMusic()
            }
        }
    }
    
    @Published var isShuffleEnabled: Bool = true {
        didSet {
            saveShuffleEnabled()
        }
    }
    
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var currentBGMIndex: Int = 0
    private let volumeKey = "soundVolume"
    private let bgmEnabledKey = "bgmEnabled"
    private let bgmTypeKey = "bgmType"
    private let customBGMUrlsKey = "customBGMUrls"
    private let shuffleEnabledKey = "shuffleEnabled"
    
    override init() {
        super.init()
        loadSettings()
        setupAudioSession()
        setupAppLifecycleObservers()
        // BGMの自動開始を削除（手動開始に変更）
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func startBGMAfterLoading() {
        if isBGMEnabled {
            playBackgroundMusic()
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func playBackgroundMusic() {
        guard isBGMEnabled else { return }
        
        // 既に再生中の場合は停止してから新しい曲を再生
        if let player = backgroundMusicPlayer, player.isPlaying {
            player.stop()
        }
        
        var urlToPlay: URL?
        
        switch selectedBGMType {
        case .defaultBGM:
            // デフォルトBGMを再生（ファイルがない場合は何もしない）
            urlToPlay = Bundle.main.url(forResource: "default_bgm", withExtension: "mp3")
            if urlToPlay == nil {
                print("Default BGM file not found. Please add 'default_bgm.mp3' to the project.")
                return
            }
        case .custom:
            // カスタムBGMを再生
            if !customBGMUrls.isEmpty {
                if isShuffleEnabled {
                    urlToPlay = customBGMUrls.randomElement()
                } else {
                    urlToPlay = customBGMUrls[currentBGMIndex % customBGMUrls.count]
                }
            } else {
                // カスタムBGMが空の場合はデフォルトに自動切り替え
                print("No custom BGM available. Switching to default BGM.")
                selectedBGMType = .defaultBGM
                saveBGMType()
                urlToPlay = Bundle.main.url(forResource: "default_bgm", withExtension: "mp3")
                if urlToPlay == nil {
                    print("Default BGM file not found. Please add 'default_bgm.mp3' to the project.")
                    return
                }
            }
        }
        
        guard let url = urlToPlay else { return }
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.numberOfLoops = 0  // 1曲終了後に次の曲へ
            backgroundMusicPlayer?.volume = Float(volume)
            backgroundMusicPlayer?.delegate = self
            backgroundMusicPlayer?.play()
        } catch {
            print("Failed to play background music: \(error)")
        }
    }
    
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
    }
    
    func playNextBGM() {
        if selectedBGMType == .custom {
            if !customBGMUrls.isEmpty {
                if isShuffleEnabled {
                    // ランダムに次の曲を選択
                    currentBGMIndex = Int.random(in: 0..<customBGMUrls.count)
                } else {
                    // 順番に次の曲へ
                    currentBGMIndex = (currentBGMIndex + 1) % customBGMUrls.count
                }
            } else {
                // カスタムBGMが空の場合はデフォルトに切り替え
                selectedBGMType = .defaultBGM
                saveBGMType()
            }
        }
        playBackgroundMusic()
    }
    
    func addCustomBGM(url: URL) {
        if !customBGMUrls.contains(url) {
            customBGMUrls.append(url)
        }
    }
    
    func removeCustomBGM(at index: Int) {
        guard index < customBGMUrls.count else { return }
        customBGMUrls.remove(at: index)
    }
    
    func playSound(named soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = Float(volume)
            player.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }
    
    private func updateVolume() {
        backgroundMusicPlayer?.volume = Float(volume)
    }
    
    private func saveVolume() {
        UserDefaults.standard.set(volume, forKey: volumeKey)
    }
    
    private func saveBGMEnabled() {
        UserDefaults.standard.set(isBGMEnabled, forKey: bgmEnabledKey)
    }
    
    private func saveBGMType() {
        UserDefaults.standard.set(selectedBGMType.rawValue, forKey: bgmTypeKey)
    }
    
    private func saveCustomBGMUrls() {
        let urlStrings = customBGMUrls.map { $0.absoluteString }
        UserDefaults.standard.set(urlStrings, forKey: customBGMUrlsKey)
    }
    
    private func saveShuffleEnabled() {
        UserDefaults.standard.set(isShuffleEnabled, forKey: shuffleEnabledKey)
    }
    
    private func loadSettings() {
        // 初起動判定用のキー
        let isFirstLaunchKey = "isFirstLaunch"
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: isFirstLaunchKey)
        
        if UserDefaults.standard.object(forKey: volumeKey) != nil {
            volume = UserDefaults.standard.double(forKey: volumeKey)
        }
        
        if UserDefaults.standard.object(forKey: bgmEnabledKey) != nil {
            isBGMEnabled = UserDefaults.standard.bool(forKey: bgmEnabledKey)
        }
        
        if let typeString = UserDefaults.standard.string(forKey: bgmTypeKey),
           let type = BGMType(rawValue: typeString) {
            selectedBGMType = type
        }
        
        if let urlStrings = UserDefaults.standard.stringArray(forKey: customBGMUrlsKey) {
            customBGMUrls = urlStrings.compactMap { URL(string: $0) }
        }
        
        if UserDefaults.standard.object(forKey: shuffleEnabledKey) != nil {
            isShuffleEnabled = UserDefaults.standard.bool(forKey: shuffleEnabledKey)
        }
        
        // 初起動時またはカスタムBGMが選択されているがファイルがない場合はデフォルトに設定
        if isFirstLaunch || (selectedBGMType == .custom && customBGMUrls.isEmpty) {
            selectedBGMType = .defaultBGM
            saveBGMType()
            
            // 初起動フラグを設定
            if isFirstLaunch {
                UserDefaults.standard.set(true, forKey: isFirstLaunchKey)
            }
        }
    }
    
    func resetToDefaults() {
        volume = 0.5
        isBGMEnabled = true
        selectedBGMType = .defaultBGM
        customBGMUrls = []
        isShuffleEnabled = true
    }
    
    // アプリのライフサイクルイベントを監視
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appWillTerminate() {
        print("App will terminate - stopping background music")
        stopBackgroundMusic()
    }
    
    @objc private func appDidEnterBackground() {
        // バックグラウンドでの音楽継続は許可（ユーザーが望む場合）
        print("App entered background - music continues if enabled")
    }
    
    @objc private func appWillEnterForeground() {
        // フォアグラウンド復帰時に必要に応じて再生を再開
        print("App will enter foreground")
        if isBGMEnabled && backgroundMusicPlayer?.isPlaying == false {
            playBackgroundMusic()
        }
    }
}

// AVAudioPlayerDelegateを実装して曲終了時に次の曲を再生
extension SoundManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag && isBGMEnabled {
            playNextBGM()
        }
    }
}