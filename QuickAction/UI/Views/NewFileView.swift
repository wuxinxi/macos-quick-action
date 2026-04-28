import SwiftUI

struct NewFileView: View {
    @ObservedObject var manager: TemplateManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Settings
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "Creation Settings"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                HStack {
                    Toggle(String(localized: "Automated Launch"), isOn: $manager.openAfterCreate)
                        .toggleStyle(.switch)
                        .onChange(of: manager.openAfterCreate) { _ in
                            manager.saveSettings()
                        }
                    
                    Spacer()
                    
                    Text(String(localized: "Create a new file and open it after creation"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                .cornerRadius(10)
            }
            .padding(20)
            
            Divider().padding(.horizontal, 20)
            
            // Templates Grid-ish List
            ScrollView {
                VStack(spacing: 12) {
                    Text(String(localized: "FILE TEMPLATES"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 4)
                    
                    ForEach($manager.templates) { $template in
                        TemplateRow(template: $template) {
                            manager.saveSettings()
                        }
                    }
                }
                .padding(20)
            }
        }
    }
}

struct TemplateRow: View {
    @Binding var template: FileTemplate
    let onToggle: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: template.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(template.localizedName)
                    .font(.system(size: 13, weight: .medium))
                Text(".\(template.extensionName)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $template.isEnabled)
                .labelsHidden()
                .onChange(of: template.isEnabled) { _ in
                    onToggle()
                }
        }
        .padding(10)
        .background(isHovered ? Color.primary.opacity(0.05) : Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(10)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}
