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

    override func viewDidLoad() {
        super.viewDidLoad()
        hideUnreleasedTabs()
    }

    /// 以 root VC 的型別辨識要隱藏的 tab，而非索引位置。
    /// 索引寫死（[1, 2]）有兩個弱點：日後調整 storyboard 的 tab 順序會靜默刪錯 tab；
    /// 且重複執行會誤刪（第二次的索引 1、2 已是收藏與個人檔案）。型別判斷對兩者皆免疫。
    private func hideUnreleasedTabs() {
        guard let allTabs = viewControllers else { return }
        viewControllers = allTabs.filter { tab in
            let root = (tab as? UINavigationController)?.viewControllers.first ?? tab
            return !(root is AdoptionViewController || root is SharePetCollectionViewController)
        }
    }
}
