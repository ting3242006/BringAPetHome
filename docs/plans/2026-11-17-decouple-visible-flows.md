# 可見流程解耦（2026-11-17）

分支：`refactor/decouple-visible-flows`（自 main `3bd3bab`）。

## 鐵則

- 不改 UI、Storyboard、約束、文案、畫面流程與時序。
- 隱藏流程（`Controller/Adoption`、`Controller/Share`、`View/Adoption`、`View/Share`、`AdoptionManager`、`ShareManager`、`AdoptionModel`、`ShareModel`）一行不動；唯一例外是 Task A 的 `databaseRef`。
- 行為不變：既有的資料往返遺失欄位、預設值不一致等現況一律原樣保留，不順手修。

## 任務

- [ ] **A 清理**：刪可見流程內的零引用程式碼與多餘 import；刪根目錄孤兒檔 `User+CoreDataClass.swift`；移除 `FirebaseDatabase`（`AdoptionViewController` 的 `databaseRef` 與 pbxproj 連結）；本機 `Pods/` 已刪。
  - 不刪 `ShareManager.fetchUserSharing`：hide-tabs 規格恢復「我的分享」時要用。
- [ ] **B 首頁／收藏**：`Filter` 由 `HomeFilterViewController.swift` 移到 `Model/ShelterDataModel.swift`；`ShelterManager` 的 API URL 兩處收斂為一個常數；新增 `Model/FavoriteStore.swift` 收攏 CoreData 存取與 `AnimalData`↔`Animal` 對映，`HomeDetailViewController`、`FavoriteListViewController` 改用它。
- [ ] **C 個人檔案**：`ProfileViewController`、`EditProfileViewController` 不再直接呼叫 Firebase；登入狀態／登出、刪除 User 文件、頭像上傳移入 Model 層。
- [ ] **D 文件**：新增 `docs/ARCHITECTURE.md`（分層規則與更新寫法）；`AGENTS.md` 加指向並移除 main 上不存在的項目；`CLAUDE.md` 更新測試數量。
- [ ] **E 驗證**：專案 `CLAUDE.md` 的 build 與單元測試全綠。

## 刻意不做（留給日後，依 `docs/ARCHITECTURE.md` 規則處理）

- `SignInWithAppleVC` 的 Auth 流程：無法在 CLI 驗證 Apple 登入，維持現況並列為已知例外。
- `SceneDelegate` deep link 讀取 `HomeViewController` 內部狀態：與畫面時序相關，剛修過且有測試。
- Storyboard ID／顏色／圖片名字串集中化、`tabBar.isHidden` 散落：收益低或會碰到轉場時序。
- 隱藏流程的全部耦合點（封鎖名單、圖片上傳、CoreML 辨識、`[[String: Any]]`）：恢復 tab 時再依規則改寫。

## 進度

（每個任務驗證通過後回寫）
