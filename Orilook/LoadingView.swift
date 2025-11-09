//
//  LoadingView.swift
//  Orilook
//
//  Created by 糟谷歩志 on 2025/08/22.
//

import SwiftUI

struct LoadingView: View {
    @Binding var isLoading: Bool
    @State var TitleO: CGFloat = 0
    @State var RectO: CGFloat = 1
    @State var ArectHue: CGFloat = CGFloat.random(in: 0...0.25)
    @State var BrectHue: CGFloat = CGFloat.random(in: 0.25...0.5)
    @State var CrectHue: CGFloat = CGFloat.random(in: 0.5...0.75)
    @State var DrectHue: CGFloat = CGFloat.random(in: 0.75...1)
    @State var MrectHue: CGFloat = 0
    @State var MrectX: CGFloat = -50
    @State var MrectY: CGFloat = -50
    @State var MrectRotationX: CGFloat = 0
    @State var MrectRotationY: CGFloat = 0
    
    var body: some View {
        ZStack{
            Rectangle()
                .fill(Color(hue: 0, saturation: 0, brightness: 1, opacity: RectO))
                .frame(width: 900, height: 1500)
                .offset(x: 0, y: 0)
            VStack{
                Text("Orilook")
                    .font(.system(size: 190, weight: .black))
                    .foregroundStyle(Color(hue: 0, saturation: 0, brightness: 0, opacity: TitleO))
                
                ZStack {
                    Rectangle()
                        .fill(Color(hue: ArectHue, saturation: 1, brightness: 1, opacity: RectO))
                        .frame(width: 100, height: 100)
                        .offset(x: -50, y: -50)
                    Rectangle()
                        .fill(Color(hue: BrectHue, saturation: 1, brightness: 1, opacity: RectO))
                        .frame(width: 100, height: 100)
                        .offset(x: 50, y: -50)
                    
                    Rectangle()
                        .fill(Color(hue: CrectHue, saturation: 1, brightness: 1, opacity: RectO))
                        .frame(width: 100, height: 100)
                        .offset(x: 50, y: 50)
                    Rectangle()
                        .fill(Color(hue: DrectHue, saturation: 1, brightness: 1, opacity: RectO))
                        .frame(width: 100, height: 100)
                        .offset(x: -50, y: 50)
                    
                    Rectangle()
                        .fill(Color(hue: MrectHue, saturation: 0.75, brightness: 0.75, opacity: RectO))
                        .frame(width: 100, height: 100)
                        .rotation3DEffect(.degrees(MrectRotationX), axis: (0, 1, 0))
                        .rotation3DEffect(.degrees(MrectRotationY), axis: (1, 0, 0))
                        .offset(x: MrectX, y: MrectY)
                }
                
                .onAppear {
                    Task {
                        RectO = 1
                        ArectHue = CGFloat.random(in: 0...0.25)
                        BrectHue = CGFloat.random(in: 0.25...0.5)
                        CrectHue = CGFloat.random(in: 0.5...0.75)
                        DrectHue = CGFloat.random(in: 0.75...1)
                        
                        try? await Task.sleep(for: .seconds(0.1))
                        TitleO = 0
                        
                        withAnimation(.linear(duration: 2)) {
                            TitleO = 1
                        }
                        try? await Task.sleep(for: .seconds(0.1))
                        withAnimation {
                            MrectX = 50
                            MrectRotationX = 180
                            MrectHue = CGFloat.random(in: 0.75...1)
                            
                        }
                        try? await Task.sleep(for: .seconds(0.5))
                        withAnimation {
                            MrectY = 50
                            MrectRotationY = -180
                            MrectHue = CGFloat.random(in: 0...0.25)
                        }
                        try? await Task.sleep(for: .seconds(0.5))
                        withAnimation {
                            MrectX = -50
                            MrectRotationX = 0
                            MrectHue = CGFloat.random(in: 0.25...0.5)
                        }
                        try? await Task.sleep(for: .seconds(0.5))
                        withAnimation {
                            MrectY = -50
                            MrectRotationY = 0
                            MrectHue = CGFloat.random(in: 0.5...0.75)
                        }
                        try? await Task.sleep(for: .seconds(0.5))
                        withAnimation {
                            RectO = 0
                            TitleO = 0
                        }
                        try? await Task.sleep(for: .seconds(0.5))
                        
                        isLoading = false
                    }
                }
            }
        }
    }
}

#Preview {
    LoadingView(isLoading: .constant(true))
}
