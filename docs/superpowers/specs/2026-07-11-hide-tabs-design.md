# 隱藏送養/探索 tab（v1.2.0）設計

日期：2026-07-11
狀態：user 已核可（方案 A：SceneDelegate 過濾）

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

## 方案（A：SceneDelegate 過濾）

選擇理由：**完全不碰 Storyboard**。該檔 2158 行、已知有 constraint breaking 問題，手改 XML（刪 segue 或加 customClass）是本次最大風險來源。方案 A 的改動全為純 Swift，恢復時刪除對應段落即可。

已否決：
- 方案 B（TabBarController subclass）：需在 storyboard 加 customClass，且多一個檔案。
- 方案 C（storyboard 刪 relationship segue）：手改 XML 風險高、diff 難讀、恢復麻煩。

## 改動範圍（僅兩個 Swift 檔）

### `SceneDelegate.swift`
於 `scene(_:willConnectTo:options:)` 內，取得 `window?.rootViewController as? UITabBarController`，移除索引 1、2。

**實作注意**：必須避免「移除索引 1 後索引位移」的經典 bug——由大到小移除，或用一次性的 `enumerated().filter` 重建陣列。

以 `// MARK:` 或明確註解標示為 v1.2.0 暫時性隱藏，並寫明恢復方式（刪除本段）。

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
  2. 個人檔案頁看不到「我的分享」清單，頁面其餘元素（頭像、暱稱、編輯、登出）正常。
  3. 首頁瀏覽／篩選、收藏功能無退化。
  4. 冷啟動無 crash（索引移除若寫錯會直接崩）。
