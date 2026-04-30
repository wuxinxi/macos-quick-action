import SwiftUI

struct SettingsView: View {
    @ObservedObject var manager: TemplateManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                VStack(alignment: .leading, spacing: 15) {
                    Text("settings.permissions.section.title")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 5)

                    HStack(spacing: 18) {
                        PermissionBadge(isAuthorized: manager.hasAuthorizedDirectory)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(manager.hasAuthorizedDirectory ? "settings.permissions.status.authorized" : "settings.permissions.status.not_authorized")
                                .font(.system(size: 13, weight: .semibold))

                            Text(manager.hasAuthorizedDirectory ? "settings.permissions.description.authorized" : "settings.permissions.description.not_authorized")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            if let path = manager.authorizedDirectoryPath {
                                Text(path)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary.opacity(0.9))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }

                        Spacer(minLength: 16)

                        Button(action: {
                            manager.selectAuthorizedDirectory()
                        }) {
                            Text(manager.hasAuthorizedDirectory ? "settings.permissions.button.change" : "settings.permissions.button.authorize")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.black.opacity(0.08))
                        .foregroundStyle(.primary)
                    }
                    .padding(18)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(18)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.primary.opacity(0.08), lineWidth: 0.8))
                }
                .frame(maxWidth: 550)

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

private struct PermissionBadge: View {
    let isAuthorized: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11)
                .fill(isAuthorized ? Color.green.opacity(0.16) : Color.orange.opacity(0.16))
                .frame(width: 46, height: 46)

            Image(systemName: isAuthorized ? "lock.open.fill" : "lock.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isAuthorized ? Color.green : Color.orange)
        }
        .padding(.leading, 2)
    }
}
