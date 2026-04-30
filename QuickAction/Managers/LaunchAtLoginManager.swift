//
//  LaunchAtLoginManager.swift
//  QuickAction
//
//  Created by Sensi Wu on 2026/4/30.
//

import Foundation
import ServiceManagement

/// 封装 SMAppService 开机自启逻辑，macOS 13+ 原生 API
final class LaunchAtLoginManager: ObservableObject {

    static let shared = LaunchAtLoginManager()

    /// 当前是否已注册开机自启
    @Published var isEnabled: Bool = false

    private init() {
        refresh()
    }

    /// 从系统读取最新状态
    func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    /// 切换开机自启状态
    func toggle() {
        do {
            if isEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
            refresh()
        } catch {
            // 注册失败时（沙盒限制、权限不足等），刷新回真实状态
            refresh()
        }
    }
}
