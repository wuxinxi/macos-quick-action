//
//  AdvancedView.swift
//  QuickAction
//
//  Created by Sensi Wu on 2026/4/30.
//

import SwiftUI
import ServiceManagement

struct AdvancedView: View {
    @ObservedObject var manager: TemplateManager
    @StateObject private var launchAtLogin = LaunchAtLoginManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {

                // MARK: - Startup Section
                SectionBlock(title: "advanced.section.startup") {
                    AdvancedToggleRow(
                        icon: "bolt.fill",
                        iconColor: .accentColor,
                        label: "settings.general.launch_at_login.label",
                        footer: "settings.general.launch_at_login.footer",
                        isOn: Binding(
                            get: { launchAtLogin.isEnabled },
                            set: { _ in launchAtLogin.toggle() }
                        )
                    )
                }

                // MARK: - Quick Actions Section
                SectionBlock(title: "advanced.section.quick_actions") {
                    ForEach(manager.quickActions) { action in
                        QuickActionRow(action: action, manager: manager)

                        if action.id != manager.quickActions.last?.id {
                            Divider().padding(.leading, 62)
                        }
                    }
                }

            }
            .padding(40)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Quick Action Row

private struct QuickActionRow: View {
    let action: QuickActionItem
    @ObservedObject var manager: TemplateManager

    var body: some View {
        HStack(spacing: 14) {
            // Icon badge
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor(for: action).opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: action.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor(for: action))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(action.nameKey))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(action.isAppInstalled ? .primary : .secondary)

                if !action.isAppInstalled {
                    // 所需 App 未安装时显示提示
                    Text("advanced.quick_action.not_installed")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { action.isEnabled },
                set: { manager.setQuickActionEnabled(id: action.id, enabled: $0) }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .disabled(!action.isAppInstalled)  // 未安装时禁用开关
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .opacity(action.isAppInstalled ? 1.0 : 0.5)
    }

    private func iconColor(for action: QuickActionItem) -> Color {
        switch action.id {
        case "copy_path":    return .blue
        case "open_terminal": return .green
        case "open_sublime":  return .orange
        case "open_iterm2":   return .purple
        default:              return .accentColor
        }
    }
}

// MARK: - Reusable Section Container

private struct SectionBlock<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: () -> Content

    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = LocalizedStringKey(title)
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.leading, 5)

            VStack(spacing: 0) {
                content()
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.1), lineWidth: 0.5))
        }
        .frame(maxWidth: 550)
    }
}

// MARK: - Reusable Simple Toggle Row (for Startup etc.)

private struct AdvancedToggleRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let footer: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(label))
                    .font(.system(size: 13, weight: .medium))
                Text(LocalizedStringKey(footer))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
