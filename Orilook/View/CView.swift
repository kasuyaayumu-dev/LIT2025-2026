//
//  CView.swift
//  Orilook
//
//  Created by 糟谷歩志 on 2025/08/22.
//

import SwiftUI

struct CView: View {
    @State var isLoading: Bool = true
    
    var body: some View {
        Group {
            if isLoading {
                LoadingView(isLoading: $isLoading)
            } else {
                ContentsList()
            }
        }
    }
}

#Preview {
    CView()
        .environmentObject(LanguageManager())
        .environmentObject(FilterManager())
        .environmentObject(ViewModeManager())
        .environmentObject(CompletionManager())
        .environmentObject(NavigationManager())
        .environmentObject(ImageManager())
        .environmentObject(FavoriteManager())
        .environmentObject(TutorialManager())
        .environmentObject(SoundManager())
}
