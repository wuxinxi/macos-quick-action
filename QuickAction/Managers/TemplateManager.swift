import Foundation

class TemplateManager: ObservableObject {
    @Published var templates: [FileTemplate] = []
    @Published var openAfterCreate: Bool = false
    
    private let sharedDefaults = UserDefaults(suiteName: "group.cn.xxstudy.QuickAction")
    static let storageKey = "configured_templates"
    static let openAfterCreateKey = "open_after_create"
    
    static let defaultTemplates: [FileTemplate] = [
        FileTemplate(nameKey: "Text", extensionName: "txt", isEnabled: true, iconName: "doc.text"),
        FileTemplate(nameKey: "Markdown", extensionName: "md", isEnabled: true, iconName: "arrow.down.square"),
        FileTemplate(nameKey: "JSON", extensionName: "json", isEnabled: true, iconName: "curlybraces"),
        FileTemplate(nameKey: "HTML", extensionName: "html", isEnabled: true, iconName: "chevron.left.forwardslash.chevron.right"),
        FileTemplate(nameKey: "CSS", extensionName: "css", isEnabled: true, iconName: "number"),
        FileTemplate(nameKey: "Swift", extensionName: "swift", isEnabled: false, iconName: "swift"),
        FileTemplate(nameKey: "Python", extensionName: "py", isEnabled: false, iconName: "terminal"),
        FileTemplate(nameKey: "Word", extensionName: "docx", isEnabled: false, iconName: "doc.richtext"),
        FileTemplate(nameKey: "Excel", extensionName: "xlsx", isEnabled: false, iconName: "tablecells"),
    ]
    
    init() {
        loadSettings()
    }
    
    func loadSettings() {
        if let data = sharedDefaults?.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([FileTemplate].self, from: data) {
            self.templates = decoded
        } else {
            self.templates = Self.defaultTemplates
        }
        
        self.openAfterCreate = sharedDefaults?.bool(forKey: Self.openAfterCreateKey) ?? false
    }
    
    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(templates) {
            sharedDefaults?.set(encoded, forKey: Self.storageKey)
        }
        sharedDefaults?.set(openAfterCreate, forKey: Self.openAfterCreateKey)
    }
}
