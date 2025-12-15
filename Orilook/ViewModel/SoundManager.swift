import SwiftUI
import AVFoundation
import MediaPlayer
import UIKit

// 【修正】省略されていたEnum定義を追加
enum BGMType: String, CaseIterable, Codable {
    case defaultBGM = "default"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .defaultBGM: return "デフォルト"
        case .custom: return "カスタム"
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
                stopBackgroundMusic()
                playBackgroundMusic()
            }
        }
    }
    
    @Published var customBGMUrls: [URL] = [] {
        didSet {
            saveCustomBGMUrls()
            // 曲リストが変わった時、カスタム選択中なら再生し直す
            if selectedBGMType == .custom && isBGMEnabled {
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
        
        if let player = backgroundMusicPlayer, player.isPlaying {
            player.stop()
        }
        
        var urlToPlay: URL?
        
        switch selectedBGMType {
        case .defaultBGM:
            urlToPlay = Bundle.main.url(forResource: "default_bgm", withExtension: "mp3")
            if urlToPlay == nil {
                print("Default BGM file not found.")
                return
            }
        case .custom:
            // リストが空でも勝手にデフォルトに戻さない
            if !customBGMUrls.isEmpty {
                if isShuffleEnabled {
                    urlToPlay = customBGMUrls.randomElement()
                } else {
                    urlToPlay = customBGMUrls[currentBGMIndex % customBGMUrls.count]
                }
            } else {
                print("No custom BGM available yet. Waiting for user input.")
                stopBackgroundMusic()
                return
            }
        }
        
        guard let url = urlToPlay else { return }
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.numberOfLoops = 0
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
                    currentBGMIndex = Int.random(in: 0..<customBGMUrls.count)
                } else {
                    currentBGMIndex = (currentBGMIndex + 1) % customBGMUrls.count
                }
            }
        }
        playBackgroundMusic()
    }

    func addCustomBGM(url: URL) {
        let startAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if startAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let destinationURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)
            
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            try FileManager.default.copyItem(at: url, to: destinationURL)
            
            if !customBGMUrls.contains(destinationURL) {
                customBGMUrls.append(destinationURL)
            }
            print("Successfully added custom BGM: \(destinationURL.lastPathComponent)")
            
        } catch {
            print("Failed to copy custom BGM: \(error)")
        }
    }
    
    func removeCustomBGM(at index: Int) {
        guard index < customBGMUrls.count else { return }
        
        let urlToRemove = customBGMUrls[index]
        do {
            try FileManager.default.removeItem(at: urlToRemove)
        } catch {
            print("Failed to delete file: \(error)")
        }
        
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
        
        // 初起動時やカスタムBGMが空の場合の処理
        if isFirstLaunch || (selectedBGMType == .custom && customBGMUrls.isEmpty) {
            selectedBGMType = .defaultBGM
            saveBGMType()
            
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
    
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc private func appWillTerminate() {
        stopBackgroundMusic()
    }
    
    @objc private func appDidEnterBackground() {
    }
    
    @objc private func appWillEnterForeground() {
        if isBGMEnabled && backgroundMusicPlayer?.isPlaying == false {
            playBackgroundMusic()
        }
    }
}

extension SoundManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag && isBGMEnabled {
            playNextBGM()
        }
    }
}
