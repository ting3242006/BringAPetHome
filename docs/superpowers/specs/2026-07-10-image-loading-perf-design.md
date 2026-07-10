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

## Phase 2：修正（範圍待 Phase 1 數據決定）

依判讀規則對應動作執行，另立 plan。修完實機確認體感 + 走 FEATURE_TEST_PLAN.md 的首頁瀏覽與篩選兩項。

## 清理承諾

Phase 2 驗收通過後，`[PERF]` 量測碼整段移除（`#if DEBUG` 僅為過渡保險）。量測結論記回本文件。

## 驗證

每次改動跑專案 CLAUDE.md「驗證指令」：編譯零錯誤、動過檔案零新增警告。本專案無單元測試。
