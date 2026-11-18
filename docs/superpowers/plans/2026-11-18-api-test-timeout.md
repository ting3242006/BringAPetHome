# 政府 API 連通測試逾時診斷與最小修正

原有兩個 XCTest 直接下載整份動物資料，以手動 expectation 等待 15 秒。歷史完整套件已重現兩項 API 測試逾時；其他 25 項通過。

同一 Foundation URLSession(.default) 探針單輪量測：

| 環境 | 全量回應 | 全量時間 | top1 回應時間 |
|---|---:|---:|---:|
| macOS 27.0.1 | 約 9.214 MB | 5.121 秒 | 0.043 秒 |
| iOS 26.0 Simulator | 約 9.215 MB | 11.973 秒 | 0.215 秒 |

四組皆 HTTP 200／h2。top1 依序在同一 session 發出，重用全量請求的連線。Simulator 全量傳輸主要耗時在下載；此輪沒有重現歷史逾時，因此只能支持大型回應對外部傳輸波動敏感的推論，不能判定固定 Simulator／OS 問題、政府服務當機或歷史 -1005 的來源。主機未收集 wire/header metrics，不補造壓縮或傳輸位元組結論。

確定的測試缺陷是 expectation 等待與 URLSession timeout 不一致、錯誤路徑未 fulfill，以及 tearDown 未取消 session。最小修正維持兩個測試名稱、真實政府 UnitId 與 HTTP 200 斷言，只以 `$top=1&$skip=0` 限制連通測試負載；共用 URLComponents 建立請求。改用 async throws 的 `URLSession.data(for:)`，transport error 自然使 XCTest 失敗。request 與 resource timeout 共用 10 秒上限，tearDown 執行 invalidateAndCancel。

不使用 skip、mock、retry、放寬等待或切換 HTTP 協定來使測試通過，也不修改 production 網路流程。獨立探針的 30／45 秒 timeout 僅供診斷，沒有沿用為測試修正。

局部驗證：兩個原測試均實際請求政府端點並通過 HTTP 200 斷言，分別耗時 0.248／0.159 秒，2 項／0 失敗。驗證使用指定 iOS 26 Simulator 並停用測試診斷附件收集，以避免既有結果附件收集掛住；未改測試斷言。其餘測試內容保持原樣。

主對話最終驗證：完整 `BringAPetHomeTests` 27/27 通過，exit 0／`TEST SUCCEEDED`；兩個 API 測試於 full suite 分別耗時 6.285／5.719 秒。不同 scope 仍有環境／外網波動，局部 0.248／0.159 秒不代表固定效能。Generic iOS build exit 0／`BUILD SUCCEEDED`；變更 test file 為 0 warnings，專案維持 135 個既有 warnings／0 serious。環境為 Xcode 27.1、iOS 26.0 Simulator、iPhone 16 Pro。此輪達 `IMPLEMENTATION_COMPLETE`；尚未進行固定 HEAD 的 Claude review，故不是 `MERGE_READY`。
