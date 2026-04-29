import SwiftUI

struct SettingsView: View {
    @ObservedObject var manager: TemplateManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                // Language Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("settings.language.section.title")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 5)
                    
                    HStack {
                        Text("settings.language.picker.label")
                            .font(.system(size: 13, weight: .medium))
                        
                        Spacer()
                        
                        Menu {
                            ForEach(AppLanguage.allCases) { lang in
                                Button(action: {
                                    manager.appLanguage = lang
                                    manager.saveSettings()
                                }) {
                                    HStack {
                                        Text(LocalizedStringKey(lang.rawValue))
                                        if manager.appLanguage == lang {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(LocalizedStringKey(manager.appLanguage.rawValue))
                                    .font(.system(size: 12, weight: .medium))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(6)
                        }
                        .menuStyle(.borderlessButton)
                        .frame(minWidth: 120, alignment: .trailing)
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.1), lineWidth: 0.5))
                    
                    Text("settings.language.picker.footer")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 5)
                }
                .frame(maxWidth: 550) // Pro commercial width
                
                // Future settings can go here
                VStack(alignment: .leading, spacing: 12) {
                    Text("settings.about.section.title")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 5)
                    
                    HStack {
                        Text("QuickAction")
                        Spacer()
                        Text("v1.0.0")
                            .foregroundColor(.secondary)
                    }
                    .padding(15)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.1), lineWidth: 0.5))
                }
                .frame(maxWidth: 550)
            }
            .padding(40)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
