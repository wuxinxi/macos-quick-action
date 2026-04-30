//
//  QuickActionApp.swift
//  QuickAction
//
//  Created by Sensi Wu on 2026/4/23.
//

import SwiftUI
import AppKit

@main
struct QuickActionApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let manager = TemplateManager()
    private let isBackgroundRequestLaunch = ProcessInfo.processInfo.arguments.contains(TemplateManager.backgroundLaunchArgument)

    // 菜单栏状态图标，必须用强引用持有，否则会被释放
    private var statusItem: NSStatusItem?

    func applicationWillFinishLaunching(_ notification: Notification) {
        // 始终以 Agent 模式运行：无 Dock 图标，只活在状态栏（与小火箭、Bob 相同）
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        processCreateFileRequestFromArguments()
        manager.processPendingCreateFileRequests()

        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleCreateFileRequestNotification),
            name: Notification.Name(TemplateManager.requestNotificationName),
            object: nil
        )

        // 启动时不主动显示窗口，等用户点击状态栏图标再打开
        DispatchQueue.main.async {
            NSApp.windows.forEach { $0.orderOut(nil) }
        }

        setupStatusBarItem()
    }

    // MARK: - 菜单栏图标

    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem?.button else { return }

        // 使用 SF Symbols 的闪电图标，设为模板图（自动适配深浅色）
        let image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: "QuickAction")
        image?.isTemplate = true
        button.image = image
        button.toolTip = "QuickAction"

        // 绑定菜单
        statusItem?.menu = buildStatusMenu()

        // 为当前及未来所有窗口附加 delegate，拦截关闭按钮
        attachWindowDelegate()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(attachWindowDelegate),
            name: NSWindow.didBecomeMainNotification,
            object: nil
        )
    }

    /// 为所有窗口附加 delegate，让关闭按钮变为「隐藏」而非「终止」
    @objc private func attachWindowDelegate() {
        NSApp.windows.forEach { window in
            // 跳过系统内部窗口（如菜单、面板等）
            guard window.styleMask.contains(.titled) else { return }
            window.delegate = self
        }
    }

    private func buildStatusMenu() -> NSMenu {
        let menu = NSMenu()

        // 打开主界面（复用已有翻译 key）
        let openItem = NSMenuItem(
            title: NSLocalizedString("menu.open", comment: "Status menu: open main window"),
            action: #selector(openMainWindow),
            keyEquivalent: ""
        )
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(.separator())

        // 退出（复用已有翻译 key）
        let quitItem = NSMenuItem(
            title: NSLocalizedString("menu.quit", comment: "Status menu: quit"),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        return menu
    }

    @objc private func openMainWindow() {
        // 如果 App 已在运行，直接激活并把窗口拉到最前
        NSApp.activate(ignoringOtherApps: true)

        if let window = NSApp.windows.first(where: { !$0.isMiniaturized }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }

    private func processCreateFileRequestFromArguments() {
        let args = ProcessInfo.processInfo.arguments

        guard args.contains("--target-path"),
              let targetPathIndex = args.firstIndex(of: "--target-path"),
              targetPathIndex + 1 < args.count,
              let baseNameIndex = args.firstIndex(of: "--base-name"),
              baseNameIndex + 1 < args.count,
              let extIndex = args.firstIndex(of: "--file-ext"),
              extIndex + 1 < args.count else {
            return
        }

        let targetPath = args[targetPathIndex + 1]
        let baseName = args[baseNameIndex + 1]
        let ext = args[extIndex + 1]

        let userInfo: [String: Any] = [
            "targetDirectoryPath": targetPath,
            "baseName": baseName,
            "fileExtension": ext,
            "openAfterCreate": false
        ]

        manager.handleCreateFileRequest(userInfo: userInfo)
    }

    func applicationWillTerminate(_ notification: Notification) {
        DistributedNotificationCenter.default().removeObserver(self)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @objc private func handleCreateFileRequestNotification(_ notification: Notification) {
        if let userInfo = notification.userInfo as? [String: Any] {
            manager.handleCreateFileRequest(userInfo: userInfo)
        } else {
            manager.processPendingCreateFileRequests()
        }
    }
}

// MARK: - NSWindowDelegate（拦截关闭按钮，改为隐藏）
extension AppDelegate: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // 隐藏窗口而不是真正关闭，让 App 进程和状态栏图标继续存活
        sender.orderOut(nil)
        return false
    }
}
