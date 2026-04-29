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

    func applicationWillFinishLaunching(_ notification: Notification) {
        if isBackgroundRequestLaunch {
            NSApp.setActivationPolicy(.accessory)
        }
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

        if isBackgroundRequestLaunch {
            DispatchQueue.main.async {
                NSApp.windows.forEach { window in
                    window.orderOut(nil)
                    window.close()
                }
                NSApp.hide(nil)
            }
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
