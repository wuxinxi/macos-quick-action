import SwiftUI

struct GeneralView: View {
    @ObservedObject var manager: TemplateManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Hero Section
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(colors: [.accentColor, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 80, height: 80)
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "cursorarrow.and.square.on.square.dashed")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    
                    Text("dashboard.hero.title")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("dashboard.hero.subtitle")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Status Section
                VStack(alignment: .leading, spacing: 20) {
                    StatusRow(title: "dashboard.status.finder_ext.title", subtitle: "dashboard.status.finder_ext.subtitle", isActive: true)
                    StatusRow(title: "dashboard.status.app_group.title", subtitle: "dashboard.status.app_group.subtitle", isActive: true)
                    StatusRow(title: "dashboard.status.accessibility.title", subtitle: "dashboard.status.accessibility.subtitle", isActive: false)
                }
                .padding(20)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                
                Button(action: openExtensionSettings) {
                    Text("dashboard.button.open_settings")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Spacer()
            }
            .padding(30)
        }
    }
    
    private func openExtensionSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preferences.extensions") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct StatusRow: View {
    let title: String
    let subtitle: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Circle()
                .fill(isActive ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
                .shadow(color: (isActive ? Color.green : Color.orange).opacity(0.5), radius: 3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                    .font(.system(size: 13, weight: .medium))
                Text(LocalizedStringKey(subtitle))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: isActive ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundColor(isActive ? .green : .orange)
        }
    }
}
