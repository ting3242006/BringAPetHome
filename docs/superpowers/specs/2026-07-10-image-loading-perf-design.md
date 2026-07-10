# 首頁圖片載入效能：量測先行設計

日期：2026-07-10
狀態：user 已核可（方案 A → 帶數據做精準版方案 B）
基準：main HEAD（2ba9b65）。v1.2.0 stash 內容不納入考量（user 指示）。

## 問題

實機上（WiFi 與行動網路皆然）首頁照片載入慢，三個場景都有感：冷啟動首屏、往下滑、篩選後。測試 build 為最新 HEAD，已含 2ba9b65 / f7b359f 兩個優化 commit（downsampling、prefetch、backgroundDecode、優先權調度）。

## 已排除的假設（2026-07-10 從開發機實測）

- 政府資料 API 不慢：`$top=20` 首位元組 70–130ms，帶篩選 136ms。
- 圖片伺服器不慢：HTTP/2、單張 60–250KB PNG、首位元組 50–130ms、併發 12 張總計 0.9s。
- 網路環境不是主因：user 在 WiFi（與開發機同網）與行動網路下都慢。

## 主要嫌疑（待數據證實，不得未經量測直接修）

prefetch 洪水：初始載入後立即 prefetch「剩餘全部」；滑動時 `prefetchItemsAt` 每次新建 ImagePrefetcher 且從不取消（`cancelPrefetchingForItemsAt` 刻意留空）；prefetcher 累積於 `imagePrefetchers` 陣列。低優先權下載與可見 cell 的高優先權下載共享同一條 HTTP/2 連線頻寬，URLSession priority 僅為建議值。

## Phase 1：量測（本設計的實作範圍）

改動集中在 `BringAPetHome/Controller/Home/HomeViewController.swift`，全部以 `#if DEBUG` 包住，log 前綴 `[PERF]`：

1. `cellForItemAt` 的 `kf.setImage` 加 completion handler：記錄 indexPath、URL 尾段、耗時 ms、快取命中類型（memory / disk / none）。
2. 全域 in-flight 計數：prefetcher 啟動 +N／單張完成 -1（用 ImagePrefetcher 的 completionHandler 或 progressBlock 統計），每筆 log 附當下 in-flight 數。
3. 三個時間錨點：`viewDidLoad`、API completion、首屏第一張圖完成，各印一行 `[PERF][anchor]`。

### 測試流程（user 實機操作）

Xcode 跑實機 → 冷啟動看首屏 → 下滑 2–3 屏 → 套一次篩選 → 複製 console 全文存檔交回。約 3 分鐘。

### 判讀規則（事先寫死）

| 數據樣態 | 結論 | Phase 2 動作 |
|---|---|---|
| 可見 cell 耗時長 + in-flight 高 + 單張下載快 | prefetch 洪水 | 縮 prefetch 窗口至前方 10–20 張 + 實作取消 |
| in-flight 低 + 單張下載慢 | 伺服器/檔案大小 | 重新評估圖片代理（Cloud Function + CDN） |
| completion 快但上畫面晚 | 主執行緒/解碼 | 查解碼與 UI 更新路徑 |
| disk/memory 命中也慢 | 快取讀取或 processor 成本 | 查 processor cache key 與磁碟 IO |

## Phase 1 量測結論（2026-07-10，實機 WiFi）

原始數據：user 提供之 console log（521 行，92 行 [PERF]）。

- 冷啟動+滑動：32 張全為 cache=none，中位 6,717ms、p90 21,771ms，3 張於 30s 超時（code 2003，無重試 → 永久佔位圖）。篩選後：44 張中位 1,240ms。
- API 不慢（apiDone 於 0.180s）；首圖 0.345s 即到，其後斷崖式劣化。
- 判讀規則命中第二列（單張下載慢），但根因再收斂：
  - ❌ prefetch 洪水：全程僅一次 `prefetch start +2`；且發現 `prefetchItemsAt` 滑動時從未觸發（獨立 bug）。
  - ❌ 伺服器慢／單連線限速／HTTP3／IPv6／WAF 指紋：Mac 端 curl 多連線、curl 單連線多工、URLSession 18 並發皆 ≤1.4s 完成；伺服器無 Alt-Svc、無 AAAA。
  - ✅ 裝置端證據：非 PERF 行含 TCP RST（ESTABLISHED 收 [R.]）、`waiting fallback`（WiFi 輔助評估切換蜂窩）、`no path found for pdp_ip`。user 實機 Safari 載單張圖快、無 VPN、WiFi 輔助開啟。
- 結論（2026-07-10 經 Codex review 校正）：**冷啟動可見 cell 產生 ~8 個並發下載（log 實證 item 0–7，非先前誤估的 ~20），在該裝置的網路路徑（含 WiFi 輔助介入）下完成近乎串行（12s/22s/30s），3 張逾時且無重試**。伺服器與 app 資料流無罪。
- 量測設計缺陷（記錄供後人）：in-flight 計數僅涵蓋 prefetcher，未計 cellForItemAt 的下載，「inflight=0」不能解讀為無並發。
- Kingfisher 源碼查證（Pods/Kingfisher ImageDownloader.swift:344）：request 寫死 `.reloadIgnoringLocalCacheData` 且 `timeoutInterval = downloadTimeout`——`downloadTimeout=30` 有效；session 的 `requestCachePolicy` 對圖片下載無作用。`DelayRetryStrategy` 預設 `retryInterval = .seconds(3)`（RetryStrategy.swift:153）。

## Phase 2：修正（依數據核定範圍，經 Codex review 收緊 2026-07-10）

執行順序與驗收條件：

1. **timeout 10s + 顯式短間隔 retry**：首頁 visible image options 加 `DelayRetryStrategy(maxRetryCount: 2, retryInterval: .seconds(1))`，`downloadTimeout` 30→10。驗收：逾時後確實發生重試、不會永久卡在首次失敗（以 [PERF] log 佐證）。不承諾「消滅佔位圖」。
2. **visible path 下載節流**：節流對象是 `cell.shelterImageView.kf.setImage` 路徑（`ImagePrefetcher.maxConcurrentDownloads` 打不到主因）。實作前先把 cellForItemAt 下載納入 in-flight 計數；驗收：修正後 log 顯示同時下載 ≤N（N 於 plan 定案），且爆發樣態消失。
3. **AppDelegate session 設定清理**（定位：正確性清理，非效能修正）：移除三行對已建立 session 無效的 `sessionConfiguration.*` 賦值；不把 cache policy 當效能手段；`waitsForConnectivity` 一併移除（語意與 fail-fast+retry 相悖）。
4. **獨立診斷任務（不與 1–3 同 plan）**：`prefetchItemsAt` 不觸發、storyboard `automaticEstimatedItemSize="YES"`（line 24）與 viewDidLoad 重複 addSubview 造成的 constraint breaking、篩選後列表未回頂部。

最終驗收指標（非體感）：修正後重跑三場景 log，比對 timeout 數（基準 3）、首屏全部完成時間、p90（基準 21,771ms）。WiFi 輔助開關實驗僅作佐證，不作結論依據。

修完實機確認 + 走 FEATURE_TEST_PLAN.md 的首頁瀏覽與篩選兩項。

## 清理承諾

Phase 2 驗收通過後，`[PERF]` 量測碼整段移除（`#if DEBUG` 僅為過渡保險）。量測結論記回本文件。

## 驗證

每次改動跑專案 CLAUDE.md「驗證指令」：編譯零錯誤、動過檔案零新增警告。本專案無單元測試。
