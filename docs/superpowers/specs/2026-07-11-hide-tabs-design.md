# 隱藏送養/探索 tab（v1.2.0）設計

日期：2026-07-11
狀態：user 已核可（方案 B：TabBarController subclass。初版方案 A 於 review 被否決，見下方失敗紀錄）

## 目標

v1.2.0 上線前暫時隱藏「送養」與「探索」兩個 tab，程式碼全部保留供日後恢復。

## 現況（Explore 查證）

- TabBar 為單一 Storyboard 定義的 `UITabBarController`（`Main.storyboard:1098`，storyboardIdentifier `MainTabBarController`，**無 customClass**），5 個 tab 皆以 NavigationController 包裹：

| 索引 | 標題 | Root VC |
|---|---|---|
| 0 | 首頁 | HomeViewController |
| 1 | 送養 | AdoptionViewController |
| 2 | 探索 | SharePetCollectionViewController |
| 3 | 收藏 | FavoriteListViewController |
| 4 | 個人檔案 | ProfileViewController |

- Tab 結構 100% 由 storyboard relationship segue 決定；**無任何程式碼在 runtime 操作 `viewControllers`，亦無人依賴 tab 索引**（grep `selectedIndex` / `viewControllers[` 皆零命中）。
- **唯一的跨功能外部入口**：`ProfileViewController.swift:155-162` 的「我的分享」tableView，點選會 push 到 `ShareDetailViewController`（探索功能）。該 tableView 佔據 Profile 頁整個下半部。
- 送養/探索的其餘導航皆為各功能內部 push，tab 隱藏後即不可達。
- SceneDelegate / AppDelegate 無 deep link、無 tab 操作。

## 決議

1. **隱藏 tab 1（送養）與 tab 2（探索）**。
2. **一併隱藏 Profile 的「我的分享」入口**（user 核可）：否則探索功能仍可從個人檔案進入，形成「進得去但發不了新文」的半殘狀態。
3. Profile 頁的 tableView **直接隱藏**（user 核可），該頁成為純個人資料頁（封面、頭像、暱稱、編輯、登出），下半部留白。

## 方案（B：TabBarController subclass）

**初版採方案 A（SceneDelegate 一次性過濾）已於 review 被否決——見下方「方案 A 失敗紀錄」。**

方案 B：新增 `MainTabBarController: UITabBarController`，於 `viewDidLoad` 過濾 `viewControllers`；Storyboard 的 tabBarController 加上 `customClass`。

選擇理由：**過濾在每次實例化時執行**，任何重建 rootViewController 的路徑（含登出）都自動生效，不需逐一補洞。

### 方案 A 失敗紀錄（2026-07-11 review 發現，Critical）

`ProfileViewController.swift:77` 的**登出**按鈕會執行：

```swift
self.view.window?.rootViewController = self.storyboard?.instantiateViewController(withIdentifier: "MainTabBarController")
```

它從 Storyboard 重新實例化一個**全新的 5-tab** TabBarController，完全繞過 SceneDelegate 在 `willConnectTo` 的一次性過濾。復現：冷啟動（tab 正確隱藏）→ 進個人檔案 → 登出 → 送養/探索 tab 重新出現。

教訓：**一次性的 runtime 過濾，其正確性依賴「沒有任何地方重建該物件」這個無法在本地驗證的全域假設。** 初版 Explore 查了 SceneDelegate/AppDelegate 無 tab 操作，卻沒查 `rootViewController =` 的賦值點。改用 subclass 後，過濾與物件生命週期綁定，此類假設不再需要。

已否決：
- 方案 A（SceneDelegate 一次性過濾）：登出繞過，見上。
- 方案 C（storyboard 刪 relationship segue）：手改 XML 風險高、diff 難讀、恢復麻煩。

## 改動範圍

### `BringAPetHome/Controller/MainTabBarController.swift`（新增）
`UITabBarController` subclass，`viewDidLoad` 內過濾 `viewControllers`。

**以 root VC 的型別辨識，而非索引位置**：`root is AdoptionViewController || root is SharePetCollectionViewController`。寫死索引 `[1, 2]` 有兩個弱點——日後調整 storyboard 的 tab 順序會靜默刪錯 tab；且非冪等（重複執行時索引 1、2 已是收藏與個人檔案）。型別判斷對兩者皆免疫，也更能表達「隱藏這兩個功能」的意圖。

**必須手動加入 Xcode target**（本專案已知坑，見 CLAUDE.md）。**若漏掉，編譯仍會成功，但 Storyboard 找不到該 class，靜默 fallback 成普通 `UITabBarController`，功能完全不生效**——這是最危險的失敗模式，驗收必須確認檔案在 target 的 Sources build phase 內。

### `BringAPetHome/View/Base.lproj/Main.storyboard`
tabBarController（`Main.storyboard:1098`）加上 `customClass="MainTabBarController" customModule="BringAPetHome" customModuleProvider="target"`。僅新增 attribute，不動 segue 結構。

### `SceneDelegate.swift`
不改（初版的過濾已撤除）。

### `ProfileViewController.swift`
- `viewDidLoad` 加 `tableView.isHidden = true`。
- 移除 `viewWillAppear`（:44-47）與 `getUserProfile` 相關處（:125-127）的兩處 `fetchUserSharing` 呼叫，避免無謂的 Firestore 讀取。
- `shareList` 屬性、`UITableViewDataSource`/`Delegate` 的全部實作（含 `didSelectRowAt` 的 push）**保留不動**——恢復時只需刪除上述兩項改動。

### 不動的部分
送養/探索的所有 VC、View、Model、Manager 一行不改；Firestore 既有貼文資料不受影響。

## 驗證

- 編譯：專案 CLAUDE.md「驗證指令」，BUILD SUCCEEDED + changed-file 零新增警告。
- 實機手動（無單元測試 target）：
  1. Tab bar 僅剩三個：首頁、收藏、個人檔案。
  2. **登出後 tab 仍只有三個**（方案 A 的 Critical 復現路徑，必測）。
  3. 個人檔案頁看不到「我的分享」清單，頁面其餘元素（頭像、暱稱、編輯、登出）正常。
  4. 首頁瀏覽／篩選、收藏功能無退化。
  5. 冷啟動無 crash（索引移除若寫錯會直接崩）。
