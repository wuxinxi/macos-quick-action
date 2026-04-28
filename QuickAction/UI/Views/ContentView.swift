import SwiftUI

enum NavigationItem: String, CaseIterable, Identifiable {
    case general = "General"
    case newFile = "New File"
    case apps = "Apps"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .newFile: return "doc.badge.plus"
        case .apps: return "app.window.description"
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
                    Label(String(localized: LocalizedStringResource(stringLiteral: item.rawValue)), systemImage: item.icon)
                        .padding(.vertical, 4)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle(String(localized: "QuickAction"))
            .frame(minWidth: 180)
            
            // Footer in Sidebar
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    HStack {
                        Image(systemName: "info.circle")
                        Text(String(localized: "App Group Active"))
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
                        GeneralView()
                    case .newFile:
                        NewFileView(manager: manager)
                    case .apps:
                        AppsPlaceholderView()
                    }
                } else {
                    Text(String(localized: "Select an item to continue"))
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(String(localized: LocalizedStringResource(stringLiteral: selectedItem?.rawValue ?? "")))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { manager.loadSettings() }) {
                        Label(String(localized: "Sync"), systemImage: "arrow.clockwise")
                    }
                    .help(String(localized: "Reload settings from disk"))
                }
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}

struct AppsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "app.window.description")
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
