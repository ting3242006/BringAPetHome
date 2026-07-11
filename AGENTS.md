# BringAPetHome — AGENTS.md

> 2026-07-11 自 CLAUDE.md 瘦身遷移（原始檔備份於 `CLAUDE.md.bak-20260711`，逐字對照見該檔）。
> 驗證指令已留在 `CLAUDE.md`，本檔為技術架構、資料模型、SwiftLint 規則等工作約定。

## 專案概覽

台灣在地寵物認養 iOS app，串接政府收容所開放資料 API，讓使用者瀏覽、篩選、收藏收容所動物，並提供社群送養貼文、分享故事、私訊等功能。已上架 App Store（v1.1.1 → 開發中 v1.2.0）。

- **Bundle ID**: `com.YiTing.BringAPetHome`
- **App Store ID**: `1536547532`
- **最低版本**: iOS 17.0
- **語言**: Swift
- **UI 架構**: UIKit（Storyboard + 程式碼混合）
- **專案開啟方式**: 用 `BringAPetHome.xcodeproj`

## 建置指令

```bash
# SPM 依賴由 Xcode 自動解析；初次建置前可先手動 resolve
cd /Users/yitingsung/Developer/BringAPetHome
xcodebuild -resolvePackageDependencies -project BringAPetHome.xcodeproj -scheme BringAPetHome

# CLI 建置（驗證編譯）— 完整指令與過濾方式見文末「驗證指令」節
xcodebuild -project BringAPetHome.xcodeproj -scheme BringAPetHome \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

沒有單元測試。驗證方式是編譯通過 + 實機/模擬器手動測試。

## 技術架構

### 資料來源
- **收容所動物**: 台灣農業部開放資料 API `https://data.moa.gov.tw/Service/OpenData/TransService.aspx?UnitId=QcbUEzN6E6DL`
- **用戶資料 / 貼文 / 聊天**: Firebase Firestore
- **圖片存儲**: Firebase Storage
- **登入**: Firebase Auth（Sign in with Apple）+ LINE SDK（預留）
- **本地收藏**: CoreData（Entity: `Animal`，Model: `AnimalData.xcdatamodeld`）

### 依賴（Swift Package Manager）
Package lockfile: `BringAPetHome.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`

| Package | Products | 用途 |
|---------|----------|------|
| firebase-ios-sdk | FirebaseAuth, FirebaseFirestore, FirebaseStorage, FirebaseDatabase, FirebaseCrashlytics, FirebaseCore | 後端服務、登入、圖片、Crashlytics |
| Kingfisher | Kingfisher | 圖片快取與載入 |
| IQKeyboardManager | IQKeyboardManagerSwift | 鍵盤自動管理 |
| lottie-spm | Lottie | 動畫（載入、成功） |
| MJRefresh | MJRefresh | 下拉重新整理 |
| SwiftLintPlugins | SwiftLint binary artifact | 程式碼風格檢查 |

### SwiftLint 規則注意
- 變數名稱必須 3-40 字元（不能用 `i`, `x`, `v` 等單字母變數）
- Function body 最多 100 行（超過用 `// swiftlint:disable:next function_body_length`）
- Class body 最多 350 行（超過用 `// swiftlint:disable type_body_length`）

## 關鍵資料模型

### AnimalData（政府 API）
主要欄位：`animalId`(Int), `kind`, `sex`, `bodytype`, `age`, `colour`, `animalVariety`, `shelterName`, `shelterAddress`, `shelterTel`, `albumFile`(圖片URL), `areaPkid`(Int, 地區碼 2-23), `cDate`(建立日期), `status`

### Filter（篩選條件）
定義在 `HomeFilterViewController.swift`：
```swift
struct Filter: Equatable {
    var kind: String?      // "狗" or "貓"
    var sex: String?       // "M" or "F"
    var bodytype: String?  // "SMALL", "MEDIUM", "BIG"
    var areaPkid: Int?     // 2-23
}
```

### ShelterManager 轉換方法
- `areaName(pkid:)` → 地區中文名（基隆市、臺北市...）
- `sexCh(sex:)` → "M"→"男", "F"→"女"
- `ageCh(age:)` → "CHILD"→"幼年", "ADULT"→"成年"
- `bodytypeCh(bodytype:)` → "SMALL"→"小型"

## Firestore 結構

```
User/{uid}
  ├── id, name, email, image, blockedUser[]
  ├── fcmToken (推播用)
  ├── lineUserID, lineName, lineProfilePicture (LINE, 預留)
  ├── favorites/{animalId}     ← 收藏同步
  └── preferences/filter       ← 推播偏好

Share/{docId}
  ├── shareContent, shareImageUrl, postId, createdTime, userUid
  ├── category ("general" / "adoptionStory")
  ├── shelterName?, adoptionDate?
  └── ShareComment/{commentId}  ← 留言

Adoption/{docId}
  ├── content, imageFileUrl, location, sex, age, petable (0=待領養, 1=已領養)
  ├── userId, postId, createdTime
  └── Comment/{commentId}

Chats/{chatId}
  ├── participants[], lastMessage, lastMessageTime, adoptionPostId?
  └── messages/{msgId}
        ├── senderUid, text, timestamp, isRead
```

## UI 佈局注意事項

### HomeCollectionViewCell（主格子）
使用非傳統的 anchor 方式：`trailing` 錨到 `contentView.leadingAnchor` + 固定 `width: 170, height: 200`。**不要改動這個約束**，會導致整個首頁排版錯亂。橫向區塊已用獨立的 `NewAnimalCollectionViewCell` 解決。

### Storyboard vs 程式碼
- HomeViewController 的 collectionView 是 IBOutlet（Storyboard）
- HomeCollectionViewCell、NewAnimalCollectionViewCell 是純程式碼
- HomeDetailViewController 用 Storyboard（IBOutlet: tableView, backButton）
- AdoptionViewController 用 Storyboard
- 新增的 VC（SwipeExplorer、ShelterMap、Chat）全部是純程式碼

### 顏色
Assets 中定義：`HoneyYellow`（主色調）、`DarkGreen`、`RichBlack`

## Deep Link

- **URL Scheme**: `bringapethome://animal/{animalId}`
- 處理位置：`SceneDelegate.handleDeepLink(url:)`
- 流程：解析 animalId → 呼叫政府 API → push HomeDetailViewController

## 待完成 / 預留項目

（遷移時未逐項覆核，可能已有部分完成或過時，使用前建議先核對現況）

- [ ] LINE 登入啟用（需設定 Channel ID）
- [ ] Universal Links（搭配 Firebase Hosting，取代 Custom URL Scheme）
- [ ] Cloud Function 部署（`checkNewAnimals` 推播、`lineAuth` 驗證）
- [ ] NewAnimalCollectionViewCell 需手動加入 Xcode target
- [ ] Firestore Security Rules 更新（新增 favorites、preferences、Chats collection）
- [ ] 聊天功能的已讀/未讀 badge 顯示

## 遷移記錄與已知問題（2026-07-11）

原 CLAUDE.md 有兩節在本次瘦身中被刪除，未遷移：

- **目錄結構**（原第 53–128 行，完整檔案樹傾印）：抽查 7 個路徑後確認已過期而刪除。`AppDelegate.swift`、`Controller/Home/HomeViewController.swift`、`Controller/Home/MapViewController.swift`、`Model/ShelterDataModel.swift` 仍存在（但實際位於 `BringAPetHome/` 子目錄下，傾印裡的路徑少了這層前綴，本身就是誤導）；`CloudFunctions/checkNewAnimals/`、`Extension/AppRatingManager.swift` 已不存在；`View/Share/` 目錄現況（`ShareCollectionViewCell.swift`、`ShareCommentTableViewCell.swift`、`ShareDetailTableViewCell.swift`）與傾印中用 `...` 帶過的內容對不上。需要目錄結構時建議現場跑 `find`/`tree`，不要依賴靜態傾印。
- **測試文件**（原第 209–211 行，指向 `FEATURE_TEST_PLAN.md`）：全域搜尋確認該檔已不存在於 repo 中，刪除死連結。

⚠️ 另一發現，未在本次任務範圍內處理，僅記錄：專案根目錄下實際存在 `BringAPetHomeTests/BringAPetHomeTests.swift`，內有 2 個會實際執行的測試方法（打政府 API 驗證狀態碼）與 1 個空殼測試。這與 CLAUDE.md「驗證指令」節（逐字保留，未改動）中「無單元測試」的敘述矛盾。是否要更新驗證指令節的判準或補上 `xcodebuild test`，建議另外請 user 裁決。
