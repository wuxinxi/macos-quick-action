import Cocoa
import FinderSync

@objc(FinderSync)
class FinderSync: FIFinderSync {

    var myFolderURL = URL(fileURLWithPath: "/")

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [self.myFolderURL]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "")
        
        let copyPathItem = NSMenuItem(title: NSLocalizedString("Copy Path", comment: ""), action: #selector(copyPathAction(_:)), keyEquivalent: "")
        copyPathItem.image = menuSymbol("doc.on.doc")
        menu.addItem(copyPathItem)
        
        let terminalItem = NSMenuItem(title: NSLocalizedString("Open Terminal Here", comment: ""), action: #selector(openTerminalAction(_:)), keyEquivalent: "")
        terminalItem.image = menuSymbol("terminal")
        menu.addItem(terminalItem)
        
        let sublimeItem = NSMenuItem(title: NSLocalizedString("Open with Sublime Text", comment: ""), action: #selector(openWithSublimeAction(_:)), keyEquivalent: "")
        sublimeItem.image = menuSymbol("curlybraces")
        menu.addItem(sublimeItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Dynamic "New File" Sub-menu
        let manager = TemplateManager()
        let enabledTemplates = manager.templates.filter { $0.isEnabled }

        if !enabledTemplates.isEmpty {
            let newFileRootItem = NSMenuItem(title: NSLocalizedString("New File", comment: ""), action: nil, keyEquivalent: "")
            newFileRootItem.image = menuSymbol("doc.badge.plus")

            let subMenu = NSMenu(title: "")
            for (index, template) in enabledTemplates.enumerated() {
                let item = NSMenuItem(title: template.localizedName, action: #selector(newFileAction(_:)), keyEquivalent: "")
                item.image = menuSymbol(template.iconName)
                item.tag = index
                subMenu.addItem(item)
            }

            newFileRootItem.submenu = subMenu
            menu.addItem(newFileRootItem)
        }

        return menu
    }

    private func menuSymbol(_ name: String) -> NSImage? {
        guard let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil) else {
            return nil
        }

        let size = NSSize(width: 16, height: 16)
        
        // Brute force but highly reliable way to solve Dark/Light colors
        let appearance = NSApp.effectiveAppearance
        let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let color: NSColor = isDark ? .white : .black

        return symbol.tinted(with: color, size: size)
    }

    // MARK: - Actions
    
    @IBAction func copyPathAction(_ sender: AnyObject?) {
        guard let items = FIFinderSyncController.default().selectedItemURLs(), !items.isEmpty else { return }
        let paths = items.map { $0.path }.joined(separator: "\n")
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(paths, forType: .string)
    }

    @IBAction func openTerminalAction(_ sender: AnyObject?) {
        var targetURL: URL?
        
        if let items = FIFinderSyncController.default().selectedItemURLs(), let first = items.first {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: first.path, isDirectory: &isDir), isDir.boolValue {
                targetURL = first
            } else {
                targetURL = first.deletingLastPathComponent()
            }
        } else {
            targetURL = FIFinderSyncController.default().targetedURL()
        }
        
        guard let finalURL = targetURL else { return }
        
        // Use the native 'open' command to launch Terminal at the specific path.
        // This is much cleaner as it doesn't leave a 'cd' command in the terminal history.
        let scriptSource = """
        tell application "Terminal"
            activate
            open POSIX file "\(finalURL.path)"
        end tell
        """
        
        var errorDict: NSDictionary?
        if let script = NSAppleScript(source: scriptSource) {
            script.executeAndReturnError(&errorDict)
            if let error = errorDict { }
        }
    }

    @IBAction func openWithSublimeAction(_ sender: AnyObject?) {
        guard let items = FIFinderSyncController.default().selectedItemURLs(), !items.isEmpty else { return }
        
        let sublimeBundleIDs = ["com.sublimetext.4", "com.sublimetext.3"]
        let sublimeName = "Sublime Text"
        
        var foundBundleID: String?
        for bundleID in sublimeBundleIDs {
            if NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) != nil {
                foundBundleID = bundleID
                break
            }
        }
        
        guard let bundleID = foundBundleID else { return }
        
        // Escape double quotes in paths for AppleScript strings
        let appleScriptPaths = items.map { url in
            let escapedPath = url.path.replacingOccurrences(of: "\"", with: "\\\"")
            return "POSIX file \"\(escapedPath)\""
        }.joined(separator: ", ")
        
        let scriptSource = """
        tell application id "\(bundleID)"
            activate
            open {\(appleScriptPaths)}
        end tell
        """
        
        var errorDict: NSDictionary?
        if let script = NSAppleScript(source: scriptSource) {
            script.executeAndReturnError(&errorDict)
            if let error = errorDict { }
        }
    }
    
    @IBAction func newFileAction(_ sender: AnyObject?) {
        // Determine target folder
        var folderURL = FIFinderSyncController.default().targetedURL()

        if folderURL == nil {
            if let selected = FIFinderSyncController.default().selectedItemURLs()?.first {
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: selected.path, isDirectory: &isDir), isDir.boolValue {
                    folderURL = selected
                } else {
                    folderURL = selected.deletingLastPathComponent()
                }
            }
        }

        guard let targetURL = folderURL else { return }

        // Resolve template by tag
        let manager = TemplateManager()
        let enabledTemplates = manager.templates.filter { $0.isEnabled }
        let tag = (sender as? NSMenuItem)?.tag ?? -1
        var baseName = "Untitled"
        var ext = "txt"

        if tag >= 0 && tag < enabledTemplates.count {
            let template = enabledTemplates[tag]
            baseName = template.localizedName
            ext = template.extensionName
        }

        // Create file directly
        let fileManager = FileManager.default
        var counter = 0
        var fileURL = targetURL.appendingPathComponent("\(baseName).\(ext)")

        while fileManager.fileExists(atPath: fileURL.path) {
            counter += 1
            fileURL = targetURL.appendingPathComponent("\(baseName) \(counter).\(ext)")
        }

        do {
            try "".write(to: fileURL, atomically: true, encoding: .utf8)
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        } catch { }
    }
}

// MARK: - Extensions

extension NSImage {
    func tinted(with color: NSColor, size: NSSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        
        let rect = NSRect(origin: .zero, size: size)
        self.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
        
        color.set()
        rect.fill(using: .sourceAtop)
        
        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
