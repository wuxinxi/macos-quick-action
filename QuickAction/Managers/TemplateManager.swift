import AppKit
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
    @Published var quickActions: [QuickActionItem] = []
    @Published var openAfterCreate: Bool = false
    @Published var appLanguage: AppLanguage = .system
    @Published var authorizedDirectoryPath: String?
    
    private let sharedDefaults: UserDefaults?
    static let storageKey = "configured_templates"
    static let quickActionsKey = "new_configured_quick_actions"
    static let openAfterCreateKey = "open_after_create"
    static let languageKey = "app_language_preference"
    static let authorizedDirectoryBookmarkKey = "authorized_directory_bookmark"
    static let authorizedDirectoryPathKey = "authorized_directory_path"
    static let appGroupID = "group.cn.xxstudy.QuickAction"
    static let requestDirectoryName = "CreateFileRequests"
    static let requestNotificationName = "cn.xxstudy.QuickAction.create-file-request"
    static let backgroundLaunchArgument = "--process-create-file-requests"
    
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

    /// 快捷操作默认配置（首次启动时使用）
    static let defaultQuickActions: [QuickActionItem] = [
        QuickActionItem(id: "copy_path",    nameKey: "action.copy_path",    iconName: "doc.on.doc",    isEnabled: true,  appBundleIDs: nil),
        QuickActionItem(id: "open_terminal", nameKey: "action.open_terminal", iconName: "terminal",       isEnabled: true,  appBundleIDs: nil),
        QuickActionItem(id: "open_sublime",  nameKey: "action.open_sublime",  iconName: "curlybraces",   isEnabled: true,  appBundleIDs: ["com.sublimetext.4", "com.sublimetext.3"]),
        QuickActionItem(id: "open_iterm2",   nameKey: "action.open_iterm2",   iconName: "apple.terminal", isEnabled: false, appBundleIDs: ["com.googlecode.iterm2"]),
    ]
    
    init() {
        // Fallback to standard if App Group is not available to prevent crashes
        if let sharedDefaults = UserDefaults(suiteName: Self.appGroupID) {
            self.sharedDefaults = sharedDefaults
        } else {
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

        if let data = sharedDefaults?.data(forKey: Self.quickActionsKey),
           let decoded = try? JSONDecoder().decode([QuickActionItem].self, from: data) {
            self.quickActions = decoded
        } else {
            self.quickActions = Self.defaultQuickActions
        }

        self.openAfterCreate = sharedDefaults?.bool(forKey: Self.openAfterCreateKey) ?? false

        if let langStr = sharedDefaults?.string(forKey: Self.languageKey),
           let lang = AppLanguage(rawValue: langStr) {
            self.appLanguage = lang
        }

        loadAuthorizedDirectory()
    }
    
    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(templates) {
            sharedDefaults?.set(encoded, forKey: Self.storageKey)
        }
        if let encoded = try? JSONEncoder().encode(quickActions) {
            sharedDefaults?.set(encoded, forKey: Self.quickActionsKey)
        }
        sharedDefaults?.set(openAfterCreate, forKey: Self.openAfterCreateKey)
        sharedDefaults?.set(appLanguage.rawValue, forKey: Self.languageKey)
    }

    /// 切换某个快捷操作的启用状态并立即持久化
    func setQuickActionEnabled(id: String, enabled: Bool) {
        guard let index = quickActions.firstIndex(where: { $0.id == id }) else { return }
        quickActions[index].isEnabled = enabled
        saveSettings()
    }

    var hasAuthorizedDirectory: Bool {
        authorizedDirectoryPath != nil
    }

    static func sharedContainerURL() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    func selectAuthorizedDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.prompt = String(localized: "settings.permissions.button.change")
        panel.message = String(localized: "settings.permissions.panel.message")
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser

        guard panel.runModal() == .OK, let selectedURL = panel.url else {
            return
        }

        do {
            let bookmarkData = try selectedURL.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            sharedDefaults?.set(bookmarkData, forKey: Self.authorizedDirectoryBookmarkKey)
            sharedDefaults?.set(selectedURL.path, forKey: Self.authorizedDirectoryPathKey)
            authorizedDirectoryPath = selectedURL.path
        } catch { }
    }

    func withAuthorizedDirectoryAccess<Result>(
        to targetURL: URL,
        _ action: () throws -> Result
    ) rethrows -> Result? {
        guard let authorizedURL = resolveAuthorizedDirectoryURL() else {
            return nil
        }

        let scopedRoot = authorizedURL.standardizedFileURL.resolvingSymlinksInPath()
        let scopedTarget = targetURL.standardizedFileURL.resolvingSymlinksInPath()
        let rootPath = scopedRoot.path
        let targetPath = scopedTarget.path

        guard targetPath == rootPath || targetPath.hasPrefix(rootPath + "/") else {
            return nil
        }

        guard authorizedURL.startAccessingSecurityScopedResource() else {
            return nil
        }

        defer {
            authorizedURL.stopAccessingSecurityScopedResource()
        }

        return try action()
    }

    func enqueueCreateFileRequest(targetDirectoryURL: URL, baseName: String, ext: String) throws {
        guard let requestsDirectoryURL = Self.sharedContainerURL()?.appendingPathComponent(Self.requestDirectoryName, isDirectory: true) else {
            throw NSError(domain: "QuickAction", code: 1001, userInfo: [NSLocalizedDescriptionKey: "App Group container is unavailable."])
        }

        try FileManager.default.createDirectory(at: requestsDirectoryURL, withIntermediateDirectories: true, attributes: nil)

        let request = CreateFileRequest(
            id: UUID().uuidString,
            targetDirectoryPath: targetDirectoryURL.path,
            baseName: baseName,
            fileExtension: ext,
            openAfterCreate: openAfterCreate
        )

        let requestURL = requestsDirectoryURL.appendingPathComponent("\(request.id).json")
        let data = try JSONEncoder().encode(request)
        try data.write(to: requestURL, options: .atomic)
    }

    @discardableResult
    func processPendingCreateFileRequests() -> Int {
        guard let requestsDirectoryURL = Self.sharedContainerURL()?.appendingPathComponent(Self.requestDirectoryName, isDirectory: true) else {
            return 0
        }

        guard let requestURLs = try? FileManager.default.contentsOfDirectory(
            at: requestsDirectoryURL,
            includingPropertiesForKeys: nil
        ) else {
            return 0
        }

        var processedCount = 0

        for requestURL in requestURLs where requestURL.pathExtension == "json" {
            do {
                let data = try Data(contentsOf: requestURL)
                let request = try JSONDecoder().decode(CreateFileRequest.self, from: data)
                let createdURL = try handleCreateFileRequest(request)
                try FileManager.default.removeItem(at: requestURL)
                processedCount += 1

                if request.openAfterCreate {
                    NSWorkspace.shared.open(createdURL)
                }
            } catch {
                try? FileManager.default.removeItem(at: requestURL)
            }
        }

        return processedCount
    }

    /// Handle file creation request from DistributedNotification userInfo (no App Group access needed)
    func handleCreateFileRequest(userInfo: [String: Any]) {
        guard let targetPath = userInfo["targetDirectoryPath"] as? String,
              let baseName = userInfo["baseName"] as? String,
              let ext = userInfo["fileExtension"] as? String else {
            return
        }

        let openAfterCreate = userInfo["openAfterCreate"] as? Bool ?? false
        let targetDirectoryURL = URL(fileURLWithPath: targetPath)

        do {
            let createFile = {
                try Self.createUniqueFile(in: targetDirectoryURL, baseName: baseName, ext: ext)
            }

            let createdURL: URL
            if hasAuthorizedDirectory {
                guard let url = try withAuthorizedDirectoryAccess(to: targetDirectoryURL, createFile) else {
                    return
                }
                createdURL = url
            } else {
                createdURL = try createFile()
            }

            if openAfterCreate {
                NSWorkspace.shared.open(createdURL)
            }
        } catch { }
    }

    private func loadAuthorizedDirectory() {
        if let url = resolveAuthorizedDirectoryURL() {
            authorizedDirectoryPath = url.path
        } else {
            authorizedDirectoryPath = sharedDefaults?.string(forKey: Self.authorizedDirectoryPathKey)
        }
    }

    private func handleCreateFileRequest(_ request: CreateFileRequest) throws -> URL {
        let targetDirectoryURL = URL(fileURLWithPath: request.targetDirectoryPath)
        let createFile = {
            try Self.createUniqueFile(in: targetDirectoryURL, baseName: request.baseName, ext: request.fileExtension)
        }

        if hasAuthorizedDirectory {
            if let createdURL = try withAuthorizedDirectoryAccess(to: targetDirectoryURL, createFile) {
                return createdURL
            }
            throw NSError(
                domain: "QuickAction",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "The target directory is outside the authorized scope."]
            )
        }

        return try createFile()
    }

    private func resolveAuthorizedDirectoryURL() -> URL? {
        guard let bookmarkData = sharedDefaults?.data(forKey: Self.authorizedDirectoryBookmarkKey) else {
            return nil
        }

        var isStale = false

        do {
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                let refreshedBookmarkData = try url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                sharedDefaults?.set(refreshedBookmarkData, forKey: Self.authorizedDirectoryBookmarkKey)
                sharedDefaults?.set(url.path, forKey: Self.authorizedDirectoryPathKey)
            }

            return url
        } catch {
            return nil
        }
    }

    private static func createUniqueFile(in directoryURL: URL, baseName: String, ext: String) throws -> URL {
        let fileManager = FileManager.default
        var counter = 0
        var fileURL = directoryURL.appendingPathComponent("\(baseName).\(ext)")

        while fileManager.fileExists(atPath: fileURL.path) {
            counter += 1
            fileURL = directoryURL.appendingPathComponent("\(baseName) \(counter).\(ext)")
        }

        try "".write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}

struct CreateFileRequest: Codable {
    let id: String
    let targetDirectoryPath: String
    let baseName: String
    let fileExtension: String
    let openAfterCreate: Bool
}
