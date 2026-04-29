import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "common.language.system"
    case en = "common.language.en"
    case zhHans = "common.language.zh_hans"
    
    var id: String { self.rawValue }
    
    var locale: Locale? {
        switch self {
        case .system: return nil
        case .en: return Locale(identifier: "en")
        case .zhHans: return Locale(identifier: "zh-Hans")
        }
    }
}

class TemplateManager: ObservableObject {
    @Published var templates: [FileTemplate] = []
    @Published var openAfterCreate: Bool = false
    @Published var appLanguage: AppLanguage = .system
    
    private let sharedDefaults: UserDefaults?
    static let storageKey = "configured_templates"
    static let openAfterCreateKey = "open_after_create"
    static let languageKey = "app_language_preference"
    
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
        // Fallback to standard if App Group is not available to prevent crashes
        if let sharedDefaults = UserDefaults(suiteName: "group.cn.xxstudy.QuickAction") {
            self.sharedDefaults = sharedDefaults
        } else {
            print("⚠️ Warning: App Group container not found. Falling back to standard UserDefaults.")
            self.sharedDefaults = .standard
        }
        
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
        
        if let langStr = sharedDefaults?.string(forKey: Self.languageKey),
           let lang = AppLanguage(rawValue: langStr) {
            self.appLanguage = lang
        }
    }
    
    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(templates) {
            sharedDefaults?.set(encoded, forKey: Self.storageKey)
        }
        sharedDefaults?.set(openAfterCreate, forKey: Self.openAfterCreateKey)
        sharedDefaults?.set(appLanguage.rawValue, forKey: Self.languageKey)
    }
}
