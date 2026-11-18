# 架構規則與更新寫法

改動本專案程式碼前先讀本檔。目的：改一個功能只需讀、改少數幾個檔。
本檔只記規則；檔案位置請現場 `grep`／`find`，不要依賴靜態清單。

## 1. 分層與依賴方向

```
Controller ──▶ Model（Manager／Store／資料型別）──▶ SDK（Firebase／CoreData／URLSession）
    │
    └──▶ View（cell）
```

| 層 | 目錄 | 可以 | 不可以 |
|---|---|---|---|
| Controller | `BringAPetHome/Controller/` | 組畫面、處理使用者操作、呼叫 Model 層 | `import Firebase*`／`CoreData`；出現 `Auth.auth()`、`Firestore.firestore()`、`Storage.storage()`、`NSFetchRequest`、`URLSession` |
| View | `BringAPetHome/View/` | 顯示傳進來的值、用 delegate／closure 回報事件 | 持有 ViewController、呼叫 Manager、存取 SDK |
| Model | `BringAPetHome/Model/` | 存取 SDK、資料轉換 | `import UIKit` 的 UI 型別（alert、refresh control、VC）；引用 `Controller/` 內定義的型別 |

下表列出可見流程的功能入口。Core Data 與 Firebase Storage 的 import 規則適用於這些流程的功能程式碼。啟動程式與既有流程的例外見第 4 節。

| 需求 | 入口 |
|---|---|
| 收容所 API | `ShelterManager` |
| 本地收藏（CoreData） | `FavoriteStore`（由此檔 `import CoreData` 並處理收藏存取） |
| 登入狀態、登出、User 文件 | `UserFirebaseManager` |
| 圖片上傳（Storage） | `ImageUploader`（由此檔 `import FirebaseStorage` 並處理圖片上傳） |

## 2. 寫法規則

1. **VC 要資料就呼叫 Model 層的方法**，方法收發專案自己的型別（`AnimalData`、`UserModel`…），不把 `NSManagedObject`、`DocumentSnapshot`、`Timestamp`、`[String: Any]` 傳給 VC。
2. **共用型別放 `Model/`**，不要定義在 VC 檔裡。
3. **同一段邏輯出現第二次就抽出來**；第一次不預先抽象。
4. **不加用不到的東西**：沒有第二個實作或測試替身需求時，不加 protocol、不加 DI 容器、不加設定參數。
5. **不留死碼**：被取代的函式、屬性、import 當次刪除；不留註解掉的程式碼。
6. **寫死的值只寫一次**：API URL、Firestore collection／欄位名在所屬 Manager 內定義成常數。
7. **新增 .swift 檔要手動加進 `project.pbxproj`**（PBXBuildFile、PBXFileReference、group children、Sources build phase 共 4 處），改完跑 `plutil -lint`。
8. **不動 UI**：除非任務明確要求，不改 Storyboard、約束、文案、轉場與 callback 時序。`AGENTS.md`「UI 佈局注意事項」列的約束不可動。

## 3. 修改流程

1. `grep` 找到要改的符號，只讀相關檔，不整個目錄通讀。
2. 判斷改動屬於哪一層，依第 1 節放對位置。
3. 改完自查（應全為 0 筆）：
   ```bash
   # 可見流程的 VC 不得直連 SDK（已知例外見第 4 節）
   grep -rnE "Auth\.auth\(\)|Firestore\.firestore\(\)|Storage\.storage\(\)|NSFetchRequest|viewContext" \
     BringAPetHome/Controller/Home BringAPetHome/Controller/Profile \
     | grep -v SignInWithAppleVC
   # Model 不得反向依賴 UI 型別（已知例外見第 4 節）
   grep -rnE "UIAlertController|UIRefreshControl|ViewController" BringAPetHome/Model \
     | grep -vE "UserFirebaseManager|AdoptionManager"
   ```
4. 跑 `CLAUDE.md` 的驗證指令；改到 Model 層要加跑單元測試。
5. UI／流程改動無自動測試涵蓋，回報時要列出手動驗證步驟。

## 4. 已知例外（碰到時才依本檔規則改寫，不要順手動）

- **`AppDelegate`**：可 `import CoreData`，負責初始化持久化容器與提供共用儲存支援。收藏讀寫由 `FavoriteStore` 處理。
- **隱藏流程**：`Controller/Adoption`、`Controller/Share`、`View/Adoption`、`View/Share`、`AdoptionManager`、`ShareManager`、`AdoptionModel`、`ShareModel`。v1.2.0 由 `MainTabBarController` 隱藏，仍是舊寫法（VC 直連 Firebase、`[[String: Any]]`、重複的上傳／封鎖／辨識邏輯）。其中 `PublishAdoptionViewController` 與 `PostSharingViewController` 沿用直接 `import FirebaseStorage` 的上傳流程。恢復 tab 時，依本檔規則改寫這些流程。恢復方式見 `docs/superpowers/specs/2026-07-11-hide-tabs-design.md`。
- **`SignInWithAppleVC`**：Apple 登入流程仍在 VC 內直接用 Firebase Auth。只能在實機驗證，改動前先確認有人能實測登入。
- **`SceneDelegate` deep link**：會讀 `HomeViewController.animalDatas` 與 `HomeDetailViewController.pet`，與畫面時序綁在一起，有單元測試涵蓋。
- **`UserFirebaseManager`、`AdoptionManager`**：內含 `UIAlertController`／`UIRefreshControl`，尚未移出。
- **收藏欄位不對稱**：`FavoriteStore` 寫入與讀出 `Animal` 的欄位不完全相同（例如絕育欄位），是沿用的既有行為；要修正需當成功能變更處理並手動驗證收藏列表顯示。
