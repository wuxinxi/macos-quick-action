import SwiftUI

enum NavigationItem: String, CaseIterable, Identifiable {
    case general = "nav.tab.general"
    case newFile = "nav.tab.new_file"
    case apps = "nav.tab.apps"
    case settings = "nav.tab.settings"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .newFile: return "doc.badge.plus"
        case .apps: return "apps.ipad"
        case .settings: return "slider.horizontal.3"
        }
    }
}

struct ContentView: View {
    @StateObject private var manager = TemplateManager()
    @State private var selectedItem: NavigationItem? = .general
    
    var body: some View {
        NavigationSplitView {
            List(NavigationItem.allCases, selection: $selectedItem) { item in
                NavigationLink(value: item) {
                    Label(LocalizedStringKey(item.rawValue), systemImage: item.icon)
                        .padding(.vertical, 4)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle(Text("QuickAction"))
            .frame(minWidth: 180)
            
            // Footer in Sidebar
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    HStack {
                        Image(systemName: "info.circle")
                        Text("nav.footer.status_active")
                            .font(.caption2)
                        Spacer()
                        Circle().fill(Color.green).frame(width: 6, height: 6)
                    }
                    .padding(12)
                    .foregroundColor(.secondary)
                }
            }
        } detail: {
            Group {
                if let selectedItem = selectedItem {
                    switch selectedItem {
                    case .general:
                        GeneralView(manager: manager)
                    case .newFile:
                        NewFileView(manager: manager)
                    case .apps:
                        AppsPlaceholderView()
                    case .settings:
                        SettingsView(manager: manager)
                    }
                } else {
                    Text("Select an item to continue")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(selectedItem != nil ? Text(LocalizedStringKey(selectedItem!.rawValue)) : Text(""))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { manager.loadSettings() }) {
                        Label("Sync", systemImage: "arrow.clockwise")
                    }
                    .help(Text("Reload settings from disk"))
                }
            }
        }
        .environment(\.locale, manager.appLanguage.locale ?? Locale.current)
        .frame(minWidth: 700, minHeight: 500)
    }
}

struct AppsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 60))
                .foregroundColor(.accentColor.opacity(0.3))
            
            Text(String(localized: "App Specific Optimization"))
                .font(.headline)
            
            Text(String(localized: "Custom configurations for Terminal, Sublime Text, and more are coming soon."))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}
