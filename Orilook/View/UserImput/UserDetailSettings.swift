import SwiftUI

struct UserDetailSettings: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    
    // 設定値をバインディングで受け取る
    @Binding var step: Int
    @Binding var difficulty: Int
    @Binding var selectedTags: Set<String>
    @Binding var hasFold: Bool
    @Binding var hasOpen: Bool
    @Binding var has3D: Bool
    @Binding var hasAR: Bool
    
    // 利用可能なタグ
    private let availableTags = [
        "traditional", "animals", "simple", "toys",
        "decorations", "intermediate", "advanced", "modular"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // ステップ数設定
                stepSection
                
                Divider()
                
                // 難易度設定
                difficultySection
                
                Divider()
                
                // タグ選択
                tagsSection
                
                Divider()
                
                // 機能フラグ設定
                featuresSection
                
                // 保存ボタン
                saveButton
            }
            .padding()
        }
        .navigationTitle("作品詳細設定")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Step Section
    
    private var stepSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.number")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40)
                
                Text("ステップ数")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("折り方の手順数を設定してください")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 20) {
                    Button(action: {
                        if step > 1 {
                            step -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(step > 1 ? .blue : .gray)
                    }
                    .disabled(step <= 1)
                    
                    Text("\(step)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.primary)
                        .frame(minWidth: 80)
                    
                    Button(action: {
                        if step < 50 {
                            step += 1
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(step < 50 ? .blue : .gray)
                    }
                    .disabled(step >= 50)
                }
                .frame(maxWidth: .infinity)
                
                Text("現在: \(step)ステップ（範囲: 1-50）")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Difficulty Section
    
    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                    .frame(width: 40)
                
                Text(languageManager.localizedString("difficulty"))
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 16) {
                Text("難易度を選択してください（1-10）")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // 難易度1-5（黒い星）
                VStack(spacing: 12) {
                    Text("基本難易度（1-5）")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 20) {
                        ForEach(1...5, id: \.self) { level in
                            Button(action: {
                                difficulty = level
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: level <= difficulty ? "star.fill" : "star")
                                        .font(.system(size: 36))
                                        .foregroundColor(level <= difficulty ? .black : .gray)
                                    
                                    Text("\(level)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                // 難易度6-10（紫の星）
                VStack(spacing: 12) {
                    Text("上級難易度（6-10）")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 20) {
                        ForEach(6...10, id: \.self) { level in
                            Button(action: {
                                difficulty = level
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: level <= difficulty ? "star.fill" : "star")
                                        .font(.system(size: 36))
                                        .foregroundColor(level <= difficulty ? .purple : .gray)
                                    
                                    Text("\(level)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                Text("選択中: 難易度 \(difficulty)")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(.top, 8)
            }
            .padding()
            .background(Color.orange.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "tag.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                    .frame(width: 40)
                
                Text(languageManager.localizedString("genre"))
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("作品のジャンルを選択してください（複数選択可）")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(availableTags, id: \.self) { tag in
                        Button(action: {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: selectedTags.contains(tag) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundColor(selectedTags.contains(tag) ? .green : .gray)
                                
                                Text(languageManager.localizedString("genre_\(tag)"))
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(selectedTags.contains(tag) ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedTags.contains(tag) ? Color.green : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                if !selectedTags.isEmpty {
                    HStack {
                        Text("選択中: \(selectedTags.count)個")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Button("すべて解除") {
                            selectedTags.removeAll()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .background(Color.green.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                    .foregroundColor(.purple)
                    .frame(width: 40)
                
                Text("利用可能な機能")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 12) {
                Text("作品で利用できる表示モードを選択してください")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 10) {
                    featureToggle(
                        title: languageManager.localizedString("fold"),
                        description: "2D画像での折り方説明",
                        isEnabled: $hasFold,
                        icon: "doc.text.image",
                        color: .blue
                    )
                    
                    featureToggle(
                        title: languageManager.localizedString("open"),
                        description: "完成形の展開図",
                        isEnabled: $hasOpen,
                        icon: "square.grid.2x2",
                        color: .orange
                    )
                    
                    featureToggle(
                        title: languageManager.localizedString("3d"),
                        description: "3Dモデルでの表示",
                        isEnabled: $has3D,
                        icon: "cube",
                        color: .green
                    )
                    
                    featureToggle(
                        title: languageManager.localizedString("AR"),
                        description: "拡張現実での表示",
                        isEnabled: $hasAR,
                        icon: "arkit",
                        color: .purple
                    )
                }
            }
            .padding()
            .background(Color.purple.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    private func featureToggle(title: String, description: String, isEnabled: Binding<Bool>, icon: String, color: Color) -> some View {
        Toggle(isOn: isEnabled) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button(action: {
            dismiss()
        }) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                Text("設定を保存")
                    .font(.system(size: 24))
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(canSave ? Color.blue : Color.gray)
            .cornerRadius(12)
            .shadow(color: canSave ? .blue.opacity(0.5) : .gray.opacity(0.5), radius: 15, x: 0, y: 5)
        }
        .disabled(!canSave)
        .padding(.top, 20)
    }
    
    // MARK: - Computed Properties
    
    private var canSave: Bool {
        step >= 1 && difficulty >= 1 && !selectedTags.isEmpty
    }
}

#Preview {
    NavigationStack {
        UserDetailSettings(
            step: .constant(5),
            difficulty: .constant(3),
            selectedTags: .constant(["simple", "animals"]),
            hasFold: .constant(true),
            hasOpen: .constant(true),
            has3D: .constant(false),
            hasAR: .constant(false)
        )
    }
    .environmentObject(LanguageManager())
}
