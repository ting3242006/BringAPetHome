//
//  MainTabBarController.swift
//  BringAPetHome
//

import UIKit

/// v1.2.0 暫時隱藏「送養」與「探索」tab。
///
/// 過濾放在 subclass 的 `viewDidLoad`，而非 SceneDelegate 的一次性呼叫——
/// 因為登出（ProfileViewController）會重新 instantiate 本 controller 作為新的
/// rootViewController，一次性過濾會被繞過。
///
/// 恢復方式：刪除本檔、移除 Storyboard 中 tabBarController 的 customClass，
/// 並還原 ProfileViewController 的「我的分享」清單。
/// 詳見 docs/superpowers/specs/2026-07-11-hide-tabs-design.md
class MainTabBarController: UITabBarController {

    /// 1 = 送養（AdoptionViewController）, 2 = 探索（SharePetCollectionViewController）
    private let hiddenTabIndices: Set<Int> = [1, 2]

    override func viewDidLoad() {
        super.viewDidLoad()
        hideUnreleasedTabs()
    }

    private func hideUnreleasedTabs() {
        guard let allTabs = viewControllers else { return }
        viewControllers = allTabs.enumerated()
            .filter { !hiddenTabIndices.contains($0.offset) }
            .map { $0.element }
    }
}
