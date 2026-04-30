# macOS Finder 右键菜单「New File」功能实现指南

> 在 Finder 右键菜单中添加「新建文件」功能，支持自定义模板，无 TCC 弹窗打扰。

## 背景

macOS 的 Finder 没有原生的「新建文件」功能，Windows 用户对此习以为常，Mac 用户却只能打开编辑器手动创建。通过 FinderSync Extension，我们可以在 Finder 的右键菜单中注入自定义操作，实现一键创建文件。

## 架构概览

```
┌─────────────────────────────────────────────────────┐
│                    Finder.app                        │
│                                                     │
│   右键菜单 ──→ FinderSync Extension (FinderSyncExt)  │
│                     │                               │
│                     ├── 读取模板配置 (App Group)       │
│                     └── 直接创建文件 (FileManager)     │
│                                                     │
├─────────────────────────────────────────────────────┤
│                  主 App (QuickAction)                 │
│                                                     │
│   Settings UI ──→ 模板管理 (TemplateManager)          │
│                     │                               │
│                     └── 持久化到 App Group UserDefaults│
└─────────────────────────────────────────────────────┘
```

核心思路：**FinderSync 扩展直接创建文件，不经过主 App 中转**。

## 为什么不能通过主 App 创建文件？

最初的设计是 FinderSync → 写入 App Group → 主 App 读取并创建文件。但这会触发 macOS 的 TCC（Transparency, Consent, and Control）机制，弹出两次 **"QuickAction.app would like to access data from other apps"** 系统授权弹窗：

| 弹窗来源 | 原因 |
|---------|------|
| 第一次 | `menu(for:)` 中创建 `TemplateManager()` 读取 App Group UserDefaults |
| 第二次 | `newFileAction` 中调用 `enqueueCreateFileRequest()` 写入 App Group 容器 |

每次右键菜单弹出都会触发，用户体验极差。

## 实现方案

### 1. FinderSync 直接创建文件

将文件创建逻辑从主 App 移到 FinderSync 扩展内部：

```swift
@IBAction func newFileAction(_ sender: AnyObject?) {
    // 1. 确定目标文件夹
    var folderURL = FIFinderSyncController.default().targetedURL()

    if folderURL == nil {
        if let selected = FIFinderSyncController.default().selectedItemURLs()?.first {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: selected.path, isDirectory: &isDir),
               isDir.boolValue {
                folderURL = selected
            } else {
                folderURL = selected.deletingLastPathComponent()
            }
        }
    }

    guard let targetURL = folderURL else { return }

    // 2. 根据 tag 获取模板信息
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

    // 3. 创建文件（自动处理重名）
    var counter = 0
    var fileURL = targetURL.appendingPathComponent("\(baseName).\(ext)")

    while FileManager.default.fileExists(atPath: fileURL.path) {
        counter += 1
        fileURL = targetURL.appendingPathComponent("\(baseName) \(counter).\(ext)")
    }

    do {
        try "".write(to: fileURL, atomically: true, encoding: .utf8)
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    } catch { }
}
```

### 2. Entitlements 配置

这是整个功能最关键的配置，决定了扩展能否正常工作。

**FinderSyncExt.entitlements**：

```xml
<dict>
    <!-- 沙盒（必须保留，移除会导致扩展无法加载） -->
    <key>com.apple.security.app-sandbox</key>
    <true/>

    <!-- 临时例外：允许读写任意路径（解决文件创建权限） -->
    <key>com.apple.security.temporary-exception.files.absolute-path.read-write</key>
    <string>/</string>

    <!-- App Group：读取主 App 存储的模板配置 -->
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.cn.xxstudy.QuickAction</string>
    </array>

    <!-- AppleScript 权限（Terminal / Sublime Text 功能需要） -->
    <key>com.apple.security.scripting-targets</key>
    <dict>
        <key>com.apple.Terminal</key>
        <array>
            <string>com.apple.Terminal.app</string>
        </array>
    </dict>
    <key>com.apple.security.temporary-exception.apple-events</key>
    <array>
        <string>com.apple.Terminal</string>
        <string>com.sublimetext.3</string>
        <string>com.sublimetext.4</string>
    </array>
</dict>
```

### 3. 模板数据共享

主 App 和 FinderSync 通过 App Group (`group.cn.xxstudy.QuickAction`) 共享 `UserDefaults`：

```swift
// TemplateManager.swift
static let appGroupID = "group.cn.xxstudy.QuickAction"

init() {
    if let sharedDefaults = UserDefaults(suiteName: Self.appGroupID) {
        self.sharedDefaults = sharedDefaults
    } else {
        self.sharedDefaults = .standard
    }
}
```

主 App 的 Settings 界面修改模板配置后保存到 App Group，FinderSync 下次打开右键菜单时自动读取最新配置。

## 注意事项

### 1. sandbox 不能移除

你可能会想：参考项目 `finder-file-creator` 没有 sandbox 也能工作，我直接去掉不行吗？

**不行。** 移除 `com.apple.security.app-sandbox` 后，FinderSync 扩展会完全无法加载——右键菜单中所有自定义项全部消失，FinderSync 进程也不会启动。

原因可能是项目中引用了需要沙盒的框架（如 App Group），或者 Xcode 的签名配置要求沙盒。总之：**sandbox 必须保留**。

### 2. temporary-exception 是关键

`com.apple.security.temporary-exception.files.absolute-path.read-write` = `/` 是让 FinderSync 能在任意路径创建文件的关键。没有这个权限，沙盒会阻止扩展写入用户选择的文件夹。

### 3. 不要移除 App Group 权限

虽然文件创建不经过 App Group 了，但读取模板配置仍然需要。移除 `com.apple.security.application-groups` 后，`UserDefaults(suiteName:)` 会返回 `nil`，模板列表将回退为默认值。

### 4. 重名文件处理

创建文件时自动检测重名，追加数字后缀：

```
Untitled.txt
Untitled 1.txt
Untitled 2.txt
```

### 5. Xcode 编译注意

确保两个 target 都正确配置了 entitlements：

- **QuickAction**（主 App）→ `QuickAction.entitlements`
- **FinderSyncExt**（扩展）→ `FinderSyncExt.entitlements`

两个 target 的 App Group ID 必须完全一致。

## 完整的 FinderSync.swift 示例

```swift
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

        // 静态菜单项
        let copyPathItem = NSMenuItem(
            title: NSLocalizedString("Copy Path", comment: ""),
            action: #selector(copyPathAction(_:)), keyEquivalent: "")
        copyPathItem.image = menuSymbol("doc.on.doc")
        menu.addItem(copyPathItem)

        menu.addItem(NSMenuItem.separator())

        // 动态 New File 子菜单（从 App Group 读取配置）
        let manager = TemplateManager()
        let enabledTemplates = manager.templates.filter { $0.isEnabled }

        if !enabledTemplates.isEmpty {
            let newFileRootItem = NSMenuItem(
                title: NSLocalizedString("New File", comment: ""),
                action: nil, keyEquivalent: "")
            newFileRootItem.image = menuSymbol("doc.badge.plus")

            let subMenu = NSMenu(title: "")
            for (index, template) in enabledTemplates.enumerated() {
                let item = NSMenuItem(
                    title: template.localizedName,
                    action: #selector(newFileAction(_:)), keyEquivalent: "")
                item.image = menuSymbol(template.iconName)
                item.tag = index
                subMenu.addItem(item)
            }

            newFileRootItem.submenu = subMenu
            menu.addItem(newFileRootItem)
        }

        return menu
    }

    @IBAction func newFileAction(_ sender: AnyObject?) {
        var folderURL = FIFinderSyncController.default().targetedURL()

        if folderURL == nil {
            if let selected = FIFinderSyncController.default()
                .selectedItemURLs()?.first {
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(
                    atPath: selected.path, isDirectory: &isDir),
                   isDir.boolValue {
                    folderURL = selected
                } else {
                    folderURL = selected.deletingLastPathComponent()
                }
            }
        }

        guard let targetURL = folderURL else { return }

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

        var counter = 0
        var fileURL = targetURL.appendingPathComponent("\(baseName).\(ext)")

        while FileManager.default.fileExists(atPath: fileURL.path) {
            counter += 1
            fileURL = targetURL.appendingPathComponent(
                "\(baseName) \(counter).\(ext)")
        }

        do {
            try "".write(to: fileURL, atomically: true, encoding: .utf8)
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        } catch { }
    }

    private func menuSymbol(_ name: String) -> NSImage? {
        guard let symbol = NSImage(
            systemSymbolName: name, accessibilityDescription: nil)
        else { return nil }

        let size = NSSize(width: 16, height: 16)
        let appearance = NSApp.effectiveAppearance
        let isDark = appearance.bestMatch(
            from: [.darkAqua, .aqua]) == .darkAqua
        let color: NSColor = isDark ? .white : .black

        return symbol.tinted(with: color, size: size)
    }
}
```

## 调试技巧

- FinderSync 扩展的 `NSLog` 输出在 Console.app 中，搜索进程名 `FinderSyncExt`
- 修改 entitlements 后需要重新签名，建议 Clean Build Folder 后重新构建
- 如果菜单不出现，在终端执行 `pluginkit -m -v -i com.apple.FinderSync` 检查扩展是否注册
- 如果扩展崩溃，Finder 会静默禁用它，重启 Finder (`killall Finder`) 可重新加载

## 参考项目

- [finder-file-creator](https://github.com/salernoelia/finder-file-creator) — 无沙盒方案的参考实现
