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
        copyPathItem.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: nil)
        menu.addItem(copyPathItem)
        
        let terminalItem = NSMenuItem(title: "Open Terminal Here", action: #selector(openTerminalAction(_:)), keyEquivalent: "")
        terminalItem.image = NSImage(systemSymbolName: "terminal", accessibilityDescription: nil)
        menu.addItem(terminalItem)
        
        let sublimeItem = NSMenuItem(title: "Open with Sublime Text", action: #selector(openWithSublimeAction(_:)), keyEquivalent: "")
        sublimeItem.image = NSImage(systemSymbolName: "curlybraces", accessibilityDescription: nil)
        menu.addItem(sublimeItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let newFileItem = NSMenuItem(title: "New File from Template", action: #selector(newFileAction(_:)), keyEquivalent: "")
        newFileItem.image = NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: nil)
        menu.addItem(newFileItem)

        return menu
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
        
        // Since we are back in Sandbox, we MUST use Apple Events to securely bypass NSWorkspace limitations.
        let scriptSource = """
        tell application "Terminal"
            do script "cd '\(finalURL.path)'"
            activate
        end tell
        """
        
        var errorDict: NSDictionary?
        if let script = NSAppleScript(source: scriptSource) {
            script.executeAndReturnError(&errorDict)
            if let error = errorDict {
                NSLog("QuickAction: AppleScript Terminal error: %@", error)
            }
        }
    }

    @IBAction func openWithSublimeAction(_ sender: AnyObject?) {
        guard let items = FIFinderSyncController.default().selectedItemURLs(), !items.isEmpty else { return }
        
        let sublimeBundleIDs = ["com.sublimetext.4", "com.sublimetext.3"]
        let sublimeName = "Sublime Text"
        
        var found = false
        for bundleID in sublimeBundleIDs {
            if NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) != nil {
                found = true
                break
            }
        }
        
        guard found else {
            NSLog("QuickAction: Sublime Text not found.")
            return
        }
        
        let appleScriptPaths = items.map { "POSIX file \"\($0.path)\"" }.joined(separator: ", ")
        let scriptSource = """
        tell application "\(sublimeName)"
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
