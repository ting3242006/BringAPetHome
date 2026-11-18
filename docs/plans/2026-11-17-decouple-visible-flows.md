# 可見流程解耦（2026-11-17）

分支：`refactor/decouple-visible-flows`（自 main `3bd3bab`）。

## 鐵則

- 不改 UI、Storyboard、約束、文案、畫面流程與時序。
- 隱藏流程（`Controller/Adoption`、`Controller/Share`、`View/Adoption`、`View/Share`、`AdoptionManager`、`ShareManager`、`AdoptionModel`、`ShareModel`）一行不動；唯一例外是 Task A 的 `databaseRef`。
- 行為不變：既有的資料往返遺失欄位、預設值不一致等現況一律原樣保留，不順手修。

## 任務

- [x] **A 清理**：刪可見流程內的零引用程式碼與多餘 import；刪根目錄孤兒檔 `User+CoreDataClass.swift`；移除 `FirebaseDatabase`（`AdoptionViewController` 的 `databaseRef` 與 pbxproj 連結）；本機 `Pods/` 已刪。
  - 不刪 `ShareManager.fetchUserSharing`：hide-tabs 規格恢復「我的分享」時要用。
- [x] **B 首頁／收藏**：`Filter` 由 `HomeFilterViewController.swift` 移到 `Model/ShelterDataModel.swift`；`ShelterManager` 的 API URL 兩處收斂為一個常數；新增 `Model/FavoriteStore.swift` 收攏 CoreData 存取與 `AnimalData`↔`Animal` 對映，`HomeDetailViewController`、`FavoriteListViewController` 改用它。
- [x] **C 個人檔案**：`ProfileViewController`、`EditProfileViewController` 不再直接呼叫 Firebase；登入狀態／登出、刪除 User 文件、頭像上傳移入 Model 層。
- [x] **D 文件**：新增 `docs/ARCHITECTURE.md`（分層規則與更新寫法）；`AGENTS.md` 加指向並移除 main 上不存在的項目；`CLAUDE.md` 更新測試數量。
- [ ] **E 驗證**：專案 `CLAUDE.md` 的 build 與單元測試全綠。

## 刻意不做（留給日後，依 `docs/ARCHITECTURE.md` 規則處理）

- `SignInWithAppleVC` 的 Auth 流程：無法在 CLI 驗證 Apple 登入，維持現況並列為已知例外。
- `SceneDelegate` deep link 讀取 `HomeViewController` 內部狀態：與畫面時序相關，剛修過且有測試。
- Storyboard ID／顏色／圖片名字串集中化、`tabBar.isHidden` 散落：收益低或會碰到轉場時序。
- 隱藏流程的全部耦合點（封鎖名單、圖片上傳、CoreML 辨識、`[[String: Any]]`）：恢復 tab 時再依規則改寫。

## 進度

- A `b5ec0fb`、B `5a2df34`、C `756b956`：各自 build 通過（`** BUILD SUCCEEDED **`）。
- D：文件已更新，未 commit（`AGENTS.md` 混有 user 既有的未提交修改）。
- E：build 綠；單元測試**未全綠**。7 個純邏輯測試通過，2 個打政府 API 的測試（`testApiCallCompletes`、`testApiStatusCode`）在 5 秒 timeout 邊緣：第一輪兩個都超時，第二輪一過（4.8 秒）一超時（5.04 秒）。`curl` 同一 URL 實測回 200、9.2MB、4.1–4.4 秒。這兩個測試自己用 `URLSession` 打寫死的 URL，不經過本次改動的程式。模擬器用 iPhone 16 Pro／iOS 26.0（`CLAUDE.md` 指定的 18.2 本機沒有該機型）。
- E 後續驗證：兩個 API 測試等待上限改為 15 秒後，於 iPhone 16 Pro／iOS 26.0 執行 13 個測試全數通過（exit=0）。`testApiCallCompletes` 耗時 9.545 秒，`testApiStatusCode` 耗時 5.465 秒。
- 待手動驗證：收藏（加入／移除／列表顯示／點進詳情）、個人檔案（登出、編輯頭像與暱稱、刪除帳號）、首頁篩選。
