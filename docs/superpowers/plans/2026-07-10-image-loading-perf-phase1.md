# 首頁圖片載入量測（Phase 1）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在首頁圖片載入路徑加入 `[PERF]` 計時 log，量出每張圖的耗時、快取命中類型與同時下載數，供 Phase 2 對症下藥。

**Architecture:** 全部改動集中在 `BringAPetHome/Controller/Home/HomeViewController.swift`，以 `#if DEBUG` 包住：一個檔案私有的 `PerfLog` 工具（單調時鐘 + 執行緒安全的 in-flight 計數）、三個時間錨點、cell 圖片完成回呼計時、prefetcher 進度計數。不改任何現有行為。

**Tech Stack:** Swift / UIKit / Kingfisher 8（`kf.setImage` completionHandler、`ImagePrefetcher` progressBlock）

**Spec:** `docs/superpowers/specs/2026-07-10-image-loading-perf-design.md`

## Global Constraints

- 只准改 `BringAPetHome/Controller/Home/HomeViewController.swift`，其他檔案要動 → 停下回報。
- 所有新增碼必須在 `#if DEBUG` 內，release 組態下編譯結果與現狀等價。
- 不改變任何現有行為：不動 Kingfisher options、不動 prefetch 邏輯、不動資料流。
- SwiftLint（build phase 執行）：變數名 3–40 字元；行長 ≤120；function body ≤100 行；class body ≤350 行。
- 本專案無單元測試target，測試循環 = 專案 CLAUDE.md「驗證指令」節的編譯驗證（TDD 不適用，經 user 核可的專案現實）。
- log 一律以 `[PERF]` 開頭（之後靠這個前綴 grep 與整段移除）。

---

### Task 1: 加入 [PERF] 量測碼

**Files:**
- Modify: `BringAPetHome/Controller/Home/HomeViewController.swift`（全部改動都在此檔）

**Interfaces:**
- Consumes: 既有的 `thumbnailProcessor`、`fetchData(reset:isBackgroundPrefetch:completion:)`、`prefetchImages(from:limit:)`、`collectionView(_:prefetchItemsAt:)`（位置見下方行號）
- Produces: 無（純診斷碼，Phase 2 會整段移除）

- [ ] **Step 1: 加入 PerfLog 工具**

在 `enum PageStatus { ... }`（約第 14–17 行）之後、`class HomeViewController` 之前插入：

```swift
#if DEBUG
private enum PerfLog {
    static let appStart = CFAbsoluteTimeGetCurrent()
    private static let lock = NSLock()
    private static var inFlightCount = 0

    @discardableResult
    static func adjustInFlight(by delta: Int) -> Int {
        lock.lock()
        defer { lock.unlock() }
        inFlightCount += delta
        return inFlightCount
    }

    static func currentInFlight() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return inFlightCount
    }

    static func log(_ message: String) {
        let elapsed = String(format: "%.3f", CFAbsoluteTimeGetCurrent() - appStart)
        print("[PERF][t+\(elapsed)s] \(message)")
    }
}
#endif
```

- [ ] **Step 2: 加入首圖旗標與 viewDidLoad 錨點**

在 `private var delayedBackgroundFetch: DispatchWorkItem?`（約第 32 行）之後加入屬性：

```swift
    #if DEBUG
    private var hasLoggedFirstImageSinceReset = false
    #endif
```

在 `viewDidLoad()` 的 `super.viewDidLoad()` 之後加入：

```swift
        #if DEBUG
        PerfLog.log("anchor viewDidLoad")
        #endif
```

- [ ] **Step 3: fetchData 加入 API 錨點與旗標重置**

在 `fetchData` 內 `if reset { ... }` 區塊（約第 92–100 行）的最後（`delayedBackgroundFetch = nil` 之後）加入：

```swift
            #if DEBUG
            hasLoggedFirstImageSinceReset = false
            #endif
```

在 `ShelterManager.shared.fetchData(...)` 呼叫之前（約第 107 行前）加入：

```swift
        #if DEBUG
        PerfLog.log("api request skip=\(skip) top=\(fetchCount) reset=\(reset) bg=\(isBackgroundPrefetch)")
        #endif
```

在 completion 的 `case .success(let fetchedAnimals):`（約第 111 行）緊接著加入：

```swift
                    #if DEBUG
                    PerfLog.log("anchor apiDone fetched=\(fetchedAnimals.count) reset=\(reset)")
                    #endif
```

- [ ] **Step 4: cellForItemAt 加入完成回呼計時**

把 `cellForItemAt` 中現有的 `cell.shelterImageView.kf.setImage(...)` 呼叫（約第 255–264 行）整段替換為：

```swift
        #if DEBUG
        let requestStart = CFAbsoluteTimeGetCurrent()
        #endif
        cell.shelterImageView.kf.setImage(
            with: URL(string: item.albumFile),
            placeholder: UIImage(named: "dketch-4"),
            options: [
                .processor(thumbnailProcessor),
                .scaleFactor(UIScreen.main.scale),
                .backgroundDecode,
                .downloadPriority(1.0)
            ],
            completionHandler: { [weak self] result in
                #if DEBUG
                let elapsedMs = Int((CFAbsoluteTimeGetCurrent() - requestStart) * 1000)
                switch result {
                case .success(let value):
                    let cache = String(describing: value.cacheType)
                    let inflight = PerfLog.currentInFlight()
                    PerfLog.log("cell item=\(indexPath.item) cache=\(cache) \(elapsedMs)ms inflight=\(inflight)")
                    if let self = self, !self.hasLoggedFirstImageSinceReset {
                        self.hasLoggedFirstImageSinceReset = true
                        PerfLog.log("anchor firstImage item=\(indexPath.item)")
                    }
                case .failure(let error):
                    guard !error.isTaskCancelled else { return }
                    PerfLog.log("cell item=\(indexPath.item) FAIL \(elapsedMs)ms code=\(error.errorCode)")
                }
                #else
                _ = result
                #endif
            }
        )
```

注意：`#else _ = result #endif` 是為了避免 release 組態下 closure 參數未使用的警告；若編譯器不抱怨可省略 `#else` 段，但保留較保險。

- [ ] **Step 5: 兩處 ImagePrefetcher 加入 in-flight 計數**

先在 class 內（`prefetchImages` 方法之前）加入 DEBUG 專用 helper：

```swift
    #if DEBUG
    private func perfPrefetchProgressBlock() -> PrefetcherProgressBlock {
        return { skipped, failed, completed in
            let inflight = PerfLog.adjustInFlight(by: -1)
            let done = skipped.count + failed.count + completed.count
            if done % 10 == 0 {
                PerfLog.log("prefetch progress done=\(done) inflight=\(inflight)")
            }
        }
    }
    #endif
```

把 `prefetchImages(from:limit:)`（約第 198–212 行）內的 prefetcher 建立整段替換為：

```swift
        let options: KingfisherOptionsInfo = [
            .processor(thumbnailProcessor),
            .scaleFactor(UIScreen.main.scale),
            .backgroundDecode,
            .downloadPriority(URLSessionTask.lowPriority)
        ]
        #if DEBUG
        PerfLog.log("prefetch start +\(urls.count) inflight=\(PerfLog.adjustInFlight(by: urls.count))")
        let prefetcher = ImagePrefetcher(urls: urls, options: options,
                                         progressBlock: perfPrefetchProgressBlock())
        #else
        let prefetcher = ImagePrefetcher(urls: urls, options: options)
        #endif
        imagePrefetchers.append(prefetcher)
        prefetcher.start()
```

`collectionView(_:prefetchItemsAt:)`（約第 345–362 行）內的 prefetcher 建立做**完全相同**的替換（該處現有的 options 內容與上面相同，直接套同一段碼）。

- [ ] **Step 6: 跑驗證指令**

照專案 CLAUDE.md「驗證指令」節執行（寫檔後過濾，勿讓完整 log 進 context）：

```bash
LOG=$(mktemp -t bap-build).log
xcodebuild -workspace BringAPetHome.xcworkspace -scheme BringAPetHome \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build > "$LOG" 2>&1
echo "exit=$?"
grep -E "error:|BUILD (SUCCEEDED|FAILED)" "$LOG"
changed=$(git diff --name-only; git ls-files --others --exclude-standard)
if [ -n "$changed" ]; then
  grep "warning:" "$LOG" | grep -F -f <(printf '%s\n' "$changed") | sort -u
fi
```

Expected: `exit=0`、`** BUILD SUCCEEDED **`、changed-file 警告清單為空。

- [ ] **Step 7: Commit**

```bash
git add BringAPetHome/Controller/Home/HomeViewController.swift
git commit -m "perf: 首頁圖片載入加入 DEBUG 量測 log（Phase 1）

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## 完成後（不屬於本計畫的實作範圍）

user 依 spec 的「測試流程」實機跑三場景，回傳 console 輸出；依 spec「判讀規則」決定 Phase 2。
