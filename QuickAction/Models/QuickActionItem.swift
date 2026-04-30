//
//  QuickActionItem.swift
//  QuickAction
//
//  Created by Sensi Wu on 2026/4/30.
//

import Foundation
import AppKit

/// 单个快捷操作的数据模型（与 FileTemplate 类似，两个 Target 共享）
struct QuickActionItem: Identifiable, Codable {
    let id: String
    let nameKey: String       // 本地化 key
    let iconName: String      // SF Symbol 名称
    var isEnabled: Bool
    /// 触发该操作所需 App 的 Bundle ID 列表（nil = 不依赖任何 App，始终可用）
    let appBundleIDs: [String]?

    /// 所需 App 是否已安装（无依赖时永远为 true）
    var isAppInstalled: Bool {
        guard let bundleIDs = appBundleIDs else { return true }
        return bundleIDs.contains {
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0) != nil
        }
    }

    var localizedName: String {
        NSLocalizedString(nameKey, comment: "")
    }
}
