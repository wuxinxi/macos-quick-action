import Cocoa
import FinderSync

@objc(FinderSync)
class FinderSync: FIFinderSync {

    var myFolderURL = URL(fileURLWithPath: "/")

    override init() {
        super.init()
        NSLog("FinderSync() launched from %@", Bundle.main.bundlePath as NSString)
        FIFinderSyncController.default().directoryURLs = [self.myFolderURL]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "")
        
        let copyPathItem = NSMenuItem(title: "Copy Path", action: #selector(copyPathAction(_:)), keyEquivalent: "")
        copyPathItem.image = menuSymbol("doc.on.doc")
        menu.addItem(copyPathItem)
        
        let terminalItem = NSMenuItem(title: "Open Terminal Here", action: #selector(openTerminalAction(_:)), keyEquivalent: "")
        terminalItem.image = menuSymbol("terminal")
        menu.addItem(terminalItem)
        
        let sublimeItem = NSMenuItem(title: "Open with Sublime Text", action: #selector(openWithSublimeAction(_:)), keyEquivalent: "")
        sublimeItem.image = menuSymbol("curlybraces")
        menu.addItem(sublimeItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let newFileItem = NSMenuItem(title: "New File from Template", action: #selector(newFileAction(_:)), keyEquivalent: "")
        newFileItem.image = menuSymbol("doc.badge.plus")
        menu.addItem(newFileItem)

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
            if let error = errorDict {
                // Fallback: If 'open' fails, we might need the legacy method
                NSLog("QuickAction: AppleScript Terminal open error: %@", error)
            }
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
        
        guard let bundleID = foundBundleID else {
            NSLog("QuickAction: Sublime Text not found.")
            return
        }
        
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
            if let error = errorDict {
                NSLog("QuickAction: AppleScript error: %@", error)
            }
        }
    }
    
    @IBAction func newFileAction(_ sender: AnyObject?) {
        guard let targetURL = FIFinderSyncController.default().targetedURL() else { return }
        
        let fileManager = FileManager.default
        let baseName = "NewFile"
        let ext = "txt"
        var counter = 0
        var newFileURL = targetURL.appendingPathComponent("\(baseName).\(ext)")
        
        while fileManager.fileExists(atPath: newFileURL.path) {
            counter += 1
            newFileURL = targetURL.appendingPathComponent("\(baseName) \(counter).\(ext)")
        }
        
        // Direct file creation, no security bookmarks needed!
        fileManager.createFile(atPath: newFileURL.path, contents: "".data(using: .utf8), attributes: nil)
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
