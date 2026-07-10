# 首頁圖片載入修正（Phase 2）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 依 Phase 1 量測結論修正首頁圖片載入：逾時快速失敗＋自動重試、可見 cell 下載節流（含可驗收的 in-flight 計數）、AppDelegate 無效 session 設定清理。

**Architecture:** 全部改動在 `HomeViewController.swift` 與 `AppDelegate.swift` 兩檔。節流用 VC 內的 slot gate（cellForItemAt 與 Kingfisher 回呼都在 main thread，無需鎖）；快取命中繞過 gate；重試期間佔用 slot（以 N=4 的餘裕吸收，log 驗證）。

**Tech Stack:** Swift / UIKit / Kingfisher 8（`DelayRetryStrategy`、`ImageCache.imageCachedType`）

**Spec:** `docs/superpowers/specs/2026-07-10-image-loading-perf-design.md`（Phase 2 節，經 Codex review 收緊版）

## Global Constraints

- 只准改 `BringAPetHome/Controller/Home/HomeViewController.swift` 與 `BringAPetHome/AppDelegate.swift`。
- Phase 1 的 `[PERF]` 量測碼保留並擴充（本 Phase 驗收依賴它），仍維持 `#if DEBUG`。**節流是產品邏輯，不放在 #if DEBUG 內**。
- 驗收語言按 spec：「逾時後確實重試、不會永久卡在首次失敗」；不寫「消滅佔位圖」。
- retry 參數固定：`DelayRetryStrategy(maxRetryCount: 2, retryInterval: .seconds(1))`；timeout 固定 10 秒。節流上限 `maxConcurrentCellDownloads = 4`（軟上限：快取命中可短暫超過）。
- SwiftLint：行長 ≤120；本檔已有 `// swiftlint:disable file_length`。
- 驗證循環 = 專案 CLAUDE.md「驗證指令」（BUILD SUCCEEDED + changed-file 零新增警告）。無單元測試 target，TDD 不適用（user 核可）。

---

### Task 1: timeout 10s + 顯式短間隔 retry

**Files:**
- Modify: `BringAPetHome/AppDelegate.swift`（`downloadTimeout` 一行）
- Modify: `BringAPetHome/Controller/Home/HomeViewController.swift`（cellForItemAt 的 options 陣列）

**Interfaces:**
- Consumes: 既有 `cellForItemAt` 中 `kf.setImage` 的 options 陣列（Phase 1 已加 completionHandler）
- Produces: options 陣列含 `.retryStrategy(DelayRetryStrategy(maxRetryCount: 2, retryInterval: .seconds(1)))`（Task 2 的 `startCellDownload` 會原樣搬移這組 options）

- [ ] **Step 1: AppDelegate timeout 30→10**

`BringAPetHome/AppDelegate.swift` 中找到 `downloader.downloadTimeout = 30`，改為：

```swift
        downloader.downloadTimeout = 10
```

- [ ] **Step 2: cellForItemAt options 加 retry**

`HomeViewController.swift` 的 `cellForItemAt` 中，`kf.setImage` 的 options 陣列（現為 processor / scaleFactor / backgroundDecode / downloadPriority 四項）改為五項：

```swift
            options: [
                .processor(thumbnailProcessor),
                .scaleFactor(UIScreen.main.scale),
                .backgroundDecode,
                .downloadPriority(1.0),
                .retryStrategy(DelayRetryStrategy(maxRetryCount: 2, retryInterval: .seconds(1)))
            ],
```

- [ ] **Step 3: 跑驗證指令**

照專案 CLAUDE.md「驗證指令」節執行（寫檔後過濾）。Expected: `exit=0`、`** BUILD SUCCEEDED **`、changed-file 警告清單與基準相同（HomeViewController 既有 5 條、AppDelegate 0 條）。

- [ ] **Step 4: Commit**

```bash
git add BringAPetHome/AppDelegate.swift BringAPetHome/Controller/Home/HomeViewController.swift
git commit -m "perf: 圖片下載 timeout 30s→10s，可見 cell 加 2 次重試（間隔 1s）

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: 可見 cell 下載節流（slot gate）＋ cell in-flight 計數

**Files:**
- Modify: `BringAPetHome/Controller/Home/HomeViewController.swift`

**Interfaces:**
- Consumes: Task 1 產出的五項 options 陣列；Phase 1 的 `PerfLog`、`hasLoggedFirstImageSinceReset`
- Produces: `loadCellImage(_:urlString:at:)`、`startCellDownload(_:urlString:at:)`、`drainPendingCellLoads()`、屬性 `maxConcurrentCellDownloads`/`activeCellDownloads`/`pendingCellLoads`（診斷任務與 Phase 2 驗收會讀 `cellStart`/`cellQueue` log）

- [ ] **Step 1: 加入節流屬性**

在 `private var delayedBackgroundFetch: DispatchWorkItem?` 之後（`#if DEBUG` 屬性之前）加入：

```swift
    private let maxConcurrentCellDownloads = 4
    private var activeCellDownloads = 0
    private var pendingCellLoads: [(indexPath: IndexPath, urlString: String)] = []
```

- [ ] **Step 2: fetchData reset 時清空排隊**

`fetchData` 的 `if reset { ... }` 區塊內、`delayedBackgroundFetch = nil` 之後（Phase 1 的 `#if DEBUG` 旗標重置之前）加入：

```swift
            pendingCellLoads.removeAll()
```

- [ ] **Step 3: 加入三個節流方法**

在 `prefetchImages(from:limit:)` 方法之前加入（完整程式碼，含搬移過來的 Phase 1 計時邏輯）：

```swift
    private func loadCellImage(_ cell: HomeCollectionViewCell, urlString: String, at indexPath: IndexPath) {
        let cached = ImageCache.default.imageCachedType(
            forKey: urlString, processorIdentifier: thumbnailProcessor.identifier).cached
        if cached || activeCellDownloads < maxConcurrentCellDownloads {
            startCellDownload(cell, urlString: urlString, at: indexPath)
        } else if !pendingCellLoads.contains(where: { $0.indexPath == indexPath }) {
            cell.shelterImageView.image = UIImage(named: "dketch-4")
            pendingCellLoads.append((indexPath, urlString))
            #if DEBUG
            PerfLog.log("cellQueue enqueue item=\(indexPath.item) pending=\(pendingCellLoads.count)")
            #endif
        }
    }

    private func startCellDownload(_ cell: HomeCollectionViewCell, urlString: String, at indexPath: IndexPath) {
        activeCellDownloads += 1
        #if DEBUG
        let requestStart = CFAbsoluteTimeGetCurrent()
        PerfLog.log("cellStart item=\(indexPath.item) active=\(activeCellDownloads)")
        #endif
        cell.shelterImageView.kf.setImage(
            with: URL(string: urlString),
            placeholder: UIImage(named: "dketch-4"),
            options: [
                .processor(thumbnailProcessor),
                .scaleFactor(UIScreen.main.scale),
                .backgroundDecode,
                .downloadPriority(1.0),
                .retryStrategy(DelayRetryStrategy(maxRetryCount: 2, retryInterval: .seconds(1)))
            ],
            completionHandler: { [weak self] result in
                guard let self = self else { return }
                self.activeCellDownloads -= 1
                self.drainPendingCellLoads()
                #if DEBUG
                let elapsedMs = Int((CFAbsoluteTimeGetCurrent() - requestStart) * 1000)
                switch result {
                case .success(let value):
                    let cache = String(describing: value.cacheType)
                    PerfLog.log("cell item=\(indexPath.item) cache=\(cache) \(elapsedMs)ms active=\(self.activeCellDownloads)")
                    if !self.hasLoggedFirstImageSinceReset {
                        self.hasLoggedFirstImageSinceReset = true
                        PerfLog.log("anchor firstImage item=\(indexPath.item)")
                    }
                case .failure(let error):
                    guard !error.isTaskCancelled else { return }
                    PerfLog.log("cell item=\(indexPath.item) FAIL \(elapsedMs)ms code=\(error.errorCode)")
                }
                #endif
            }
        )
    }

    private func drainPendingCellLoads() {
        while activeCellDownloads < maxConcurrentCellDownloads, !pendingCellLoads.isEmpty {
            let next = pendingCellLoads.removeFirst()
            guard let cell = collectionView.cellForItem(at: next.indexPath) as? HomeCollectionViewCell else {
                #if DEBUG
                PerfLog.log("cellQueue skip offscreen item=\(next.indexPath.item)")
                #endif
                continue
            }
            startCellDownload(cell, urlString: next.urlString, at: next.indexPath)
        }
    }
```

設計注記（實作者需知）：
- slot 在 Kingfisher 內部重試期間持續佔用（最壞 10+1+10+1+10 ≈ 32s）；以 N=4 對可見 ~8 格的餘裕吸收，是否成立由驗收 log 判斷。
- 快取命中（memory/disk）繞過 gate 直接載，避免回滑時被慢下載堵住；因此 `active` 可能短暫 >4（軟上限，屬預期）。
- `prepareForReuse` 取消下載後 completion 仍會以 `isTaskCancelled` 觸發 → slot 釋放在 `#if DEBUG` 之外、guard 之前，任何路徑都不漏。
- 排隊項的 cell 可能已滾出畫面：`drainPendingCellLoads` 用 `collectionView.cellForItem(at:)` 判斷，不在畫面就跳過（該格重新可見時 cellForItemAt 會再走一次 gate）。

- [ ] **Step 4: cellForItemAt 改走 gate**

把 `cellForItemAt` 中整段 `#if DEBUG let requestStart ... #endif` 與 `cell.shelterImageView.kf.setImage(...)`（含 completionHandler 到收尾括號）替換為一行：

```swift
        loadCellImage(cell, urlString: item.albumFile, at: indexPath)
```

（`cell.sexLabel.text = ...` 起的後續行不動。）

- [ ] **Step 5: 跑驗證指令**

同 Task 1 Step 3。Expected: `exit=0`、`** BUILD SUCCEEDED **`、changed-file 警告與基準相同。

- [ ] **Step 6: Commit**

```bash
git add BringAPetHome/Controller/Home/HomeViewController.swift
git commit -m "perf: 可見 cell 圖片下載節流（同時最多 4 張）＋ in-flight 計數

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: AppDelegate 無效 session 設定清理（正確性清理，非效能修正）

**Files:**
- Modify: `BringAPetHome/AppDelegate.swift`

**Interfaces:**
- Consumes: Task 1 改過的 `downloader.downloadTimeout = 10`（保留）
- Produces: 無

- [ ] **Step 1: 移除三行無效設定**

`AppDelegate.swift` 中刪除以下三行（`URLSession` 建立後修改 configuration 屬性無效——session 建立時已複製 configuration；且 Kingfisher 對圖片 request 寫死 `.reloadIgnoringLocalCacheData`，cache policy 本就無作用；`waitsForConnectivity` 語意與 fail-fast+retry 相悖，一併移除）：

```swift
        downloader.sessionConfiguration.waitsForConnectivity = true
        downloader.sessionConfiguration.timeoutIntervalForRequest = 30
        downloader.sessionConfiguration.requestCachePolicy = .returnCacheDataElseLoad
```

刪除後該段應只剩：

```swift
        let downloader = ImageDownloader.default
        downloader.downloadTimeout = 10
```

- [ ] **Step 2: 跑驗證指令**

同 Task 1 Step 3。Expected: `exit=0`、`** BUILD SUCCEEDED **`、changed-file 警告清單為空（AppDelegate 基準 0 條）。

- [ ] **Step 3: Commit**

```bash
git add BringAPetHome/AppDelegate.swift
git commit -m "refactor: 移除 AppDelegate 對已建立 session 無效的三行 configuration 設定

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## 完成後（不屬於本計畫的實作範圍）

1. user 實機重跑三場景（冷啟動／下滑／篩選），提供 console log。
2. 對照基準指標：timeout 數（基準 3）、首屏全部完成時間、p90（基準 21,771ms）、`cellStart active=` 序列證明同時下載 ≤4（軟上限）。
3. 指標達標後：Opus final whole-branch review（含 Phase 1 遺留的 2 條 Minor）→ 移除 `[PERF]` 碼與 `swiftlint:disable file_length` → FEATURE_TEST_PLAN.md 首頁瀏覽與篩選兩項手動驗證。
4. 獨立診斷任務（另立 plan）：`prefetchItemsAt` 不觸發、constraint breaking、篩選後未回頂部。
