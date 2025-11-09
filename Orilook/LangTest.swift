
import SwiftUI

struct YourApp: App {
    @StateObject private var languageManager = LanguageManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageManager)
                .environment(\.locale, languageManager.language.locale)
        }
    }
}

// メインのContentViewの例
struct ContentView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @State private var showingLanguageSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(String(localized: "welcome_message"))
                    .font(.largeTitle)
                    .padding()
                
                Text("Current Language: \(languageManager.language.displayName)")
                    .font(.headline)
                
                Button(String(localized: "language_settings")) {
                    showingLanguageSettings = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Spacer()
            }
            .navigationTitle(String(localized: "app_title"))
            .sheet(isPresented: $showingLanguageSettings) {
                NavigationView {
                    LangSet()
                        .navigationTitle(String(localized: "language_settings"))
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(String(localized: "done")) {
                                    showingLanguageSettings = false
                                }
                            }
                        }
                }
            }
        }
        .environment(\.locale, languageManager.language.locale)
    }
}
