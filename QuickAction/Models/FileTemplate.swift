import Foundation

struct FileTemplate: Identifiable, Codable {
    var id: String { extensionName }
    let nameKey: String // Store the key instead of raw name
    let extensionName: String
    var isEnabled: Bool
    let iconName: String
    
    var localizedName: String {
        return NSLocalizedString(nameKey, comment: "")
    }

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
}
