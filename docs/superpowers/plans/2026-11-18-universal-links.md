# Universal Links Implementation Plan

> **For agentic workers:** 依已批准的設計序列執行，不建立 commit。實作由專責 worker 負責，主對話驗收。

**Goal:** 將動物分享改為 HTTPS Universal Links，提供未安裝 fallback，保留舊 Scheme。

**Architecture:** 延伸現有 AnimalDeepLink、AnimalShareContentBuilder 與 SceneDelegate，沿用 ShelterManager 單筆 API。Firebase Hosting 僅供靜態 fallback 與 AASA。

**Tech Stack:** Swift/UIKit/XCTest、Firebase Hosting、原生 HTML/CSS/JavaScript、Node 內建測試。

## Global Constraints

- iOS 17.0；不增加依賴，不改 Storyboard 或無關工作樹內容。
- host 唯一為 bringapethome.web.app；Firebase project/site 為 bringapethome。
- 舊 Scheme 與 snapshot 解析相容；分享提供一份完整文字，內含唯一 HTTPS 分享連結並附 `openExternalBrowser=1`，不另提供 URL item。

## 執行順序

- [x] Swift RED：修改 BringAPetHomeTests.swift 的分享預期，加入 HTTPS 接受／拒絕矩陣、Scene browsing activity 行為測試，先執行並觀察失敗。
- [x] Swift GREEN：ShelterDataModel.swift 新增 HTTPS ID URL、嚴格 parser；SceneDelegate.swift 補 cold/warm activity、最新請求識別及可延後呈現的失敗提示；entitlements 加 applinks。
- [x] 導覽狀態驗證：加測 pending failure、更新連結清除舊 pending、忽略非 browsing activity、API 失敗提示與 snapshot 舊連結回歸，執行單元測試。
- [x] Hosting RED：以 Node 內建測試驗證 AASA、Host config、fallback ID 邏輯及 App Store URL，先觀察檔案缺失／行為失敗。
- [x] Hosting GREEN：新增 firebase.json/.firebaserc、hosting/public 的 fallback、script/CSS、.well-known/apple-app-site-association，保留 .well-known、不自動轉址。
- [x] 檢查 fallback：source lint、手機／桌面畫面、有效／無效 URL 及無 JavaScript 下載連結。
- [x] 主對話跑完整 `xcodebuild -project BringAPetHome.xcodeproj -scheme BringAPetHome -destination 'platform=iOS Simulator,id=2F574B5D-B2DD-443C-9936-295F45D421D0' -only-testing:BringAPetHomeTests CODE_SIGNING_ALLOWED=NO test` 與 generic iOS build（含 SwiftLint），確認真實 exit code 與結果。最終 test/build log：`/private/tmp/bap-universal-links-final-test.log`、`/private/tmp/bap-universal-links-final-build.log`；此項為初始實作驗證，後續簽章核對與 LINE／備忘錄實機結果見下方紀錄。
- [x] 撰寫部署與實機測試步驟，區分已驗證與待驗證；不把模擬器判為線上 Universal Links 通過。

## 具體測試契約

`XCTAssertEqual(AnimalDeepLink.animalId(from: URL(string: "https://bringapethome.web.app/animal/443673")!), 443673)`；拒絕 http、偽冒 host、帳密、port、負數／零、額外 path、編碼路徑。分享以單一完整 String 提供，內含唯一 HTTPS URL 與一次 `openExternalBrowser=1`，不另提供 URL item，也不含 snapshot；canonical URL 維持 bare URL。原 snapshot fixture 仍可解析。

Hosting `node --test hosting/tests/hosting.test.cjs` 必須確認 AASA appIDs/components、Content-Type 與無 redirects、animal rewrite、App Store ID、有效 ID 的手動 Scheme URL、無效 ID 不啟用開啟按鈕。`plutil -lint BringAPetHome/BringAPetHome.entitlements` 必須成功。

## Worker 驗證紀錄

- Swift RED：`/private/tmp/bap-universal-links-red.log`，exit 65；新 HTTPS/分享/Scene 測試因功能尚未實作而失敗。既有外網 API 測試另有逾時，不作為 TDD 證據。
- Swift 局部 GREEN：`/private/tmp/bap-universal-links-green.log`，exit 0，16 tests / 0 failures；排除 2 個既有外網 API 測試。完整套件由主對話接手。
- Hosting RED：`/private/tmp/bap-hosting-red.log`，exit 1；設定與資產尚未存在。
- Hosting GREEN：`/private/tmp/bap-hosting-green.log`，exit 0，4 tests / 0 failures。
- fallback source lint：`/private/tmp/bap-fallback-lint.log`，exit 0，0 FAIL / 0 WARN。採單一 section／既有品牌範圍，不增加多圖或行銷段落；實際畫面由主對話檢視。
- Entitlements `plutil -lint`、`git diff --check` 通過。無 commit、遠端部署或實機安裝。
- 最終驗證：完整測試 18/18、generic build exit 0、Hosting deploy exit 0；部署 log：`/private/tmp/bap-universal-links-hosting-deploy.log`。當時新簽署 App entitlement 與個人 iPhone 實測尚未執行；後續已完成的項目見下方實機分享紀錄。

## 使用者核准的 review 修正（2026-11-18）

- 僅處置第 1 點失敗提示延後呈現／重試，以及第 3 點 host 大小寫問題；第 2 點 AASA `/animal/*` 範圍維持，使用者已接受現狀。
- 第 1 點：失敗提示獨立單一排程，每 0.3 秒重試，最多排程 10 次。找不到 navigation、尚未 attach window、轉場中共用同一上限。新有效連結取消舊排程並重設 budget；舊 request ID 或 token 不可修改新排程狀態。額度用盡後保留 pending，後續 scene active 仍可即時嘗試呈現，不補回額度。原 pending animal 仍維持一次延後重試。
- 第 3 點：只將 host 轉小寫後比對，保留 path、scheme、port／帳密及 ID 檢查。
- RED `/private/tmp/bap-review-fixes-red.log`：exit 65，7 tests / 4 assertion failures；已重現未 attach UI 後不顯示，以及 HTTPS/NSUserActivity/舊 Scheme 的 mixed-case host 失敗。無外網 API 測試混入本輪 RED。
- 本輪沒有 commit、部署或實機安裝，也不代表 Claude 第二輪 PASS 或 MERGE_READY。
- 本輪局部 GREEN `/private/tmp/bap-review-fixes-green.log`：exit 0，13 tests / 0 failures。包含無 navigation／window 延後 attach 後呈現一次、新有效連結取消舊 retry、純狀態 10 次上限／single-flight／舊 token 不清除新 token／取消不補額度、mixed-case host 與惡意 host/path 回歸。整合測試先觀察實際 retry 已排程再 attach，不使用固定 sleep；上限由純狀態測試即時驗證。
- 本輪 Swift 已固定，SceneDelegate.swift 266 行、UniversalLinkTests.swift 269 行，未新增 lint warning；`git diff --check` exit 0。完整 suite/build 與最終 review 由主對話接手，不把局部 GREEN 當作 MERGE_READY。

## Claude review 第1、3點修正驗證摘要

驗證摘要與限制見 [hosting/README.md](../../../hosting/README.md#2026-11-18-驗證紀錄)。失敗提示與 host 修正階段的完整測試為歷史 26/26 通過；後續分享與 API 測試修正後為 27/27 通過。簽章核對與 LINE／備忘錄實機驗證已完成，舊 snapshot 實機仍未驗證；詳見下方及 [API 測試診斷與修正](2026-11-18-api-test-timeout.md)。尚未達 `MERGE_READY`。

## 實機分享缺陷修正（2026-11-18）

- 實機從 App 分享至備忘錄只留下兩張 URL 預覽卡，動物文字與收容所電話／地址遺失；分享輸出原為含 URL 的文字加獨立 URL item。
- LINE 手動貼入同一動物網址並附 `openExternalBrowser=1`，使用者已確認冷／暖啟動都能直接進入 App。
- 最小修正為分享只提供一份完整 String，內含單一 HTTPS 分享網址；由 URLComponents 加入一次 `openExternalBrowser=1`。Canonical URL generator 維持 bare URL，HTTPS 與舊 Scheme／snapshot 解析維持原狀。
- 回歸契約涵蓋單一文字 item、完整動物／收容所聯絡資訊、系統 URL 偵測恰一個連結、query 唯一性及 canonical／帶 query 路由。使用者已確認 App 分享至備忘錄保留完整文字與可點連結，LINE 新分享冷／暖啟動皆直接到正確詳細頁。
- 局部 XCTest 25／25 通過（排除兩個外網 API 測試）；分享契約與 canonical 測試均有實際執行。當時完整套件 27 項由主對話接手，後續結果見下方；本輪變更檔未新增 lint warning。分享測試放同檔 extension 以符合實際 250 行 class body 規則。
- 本輪驗證：主對話 generic iOS build 與 Ting’s iPhone signed build 均 exit 0；簽章 App ID、`applinks`、profile 與裝置核對通過，已更新安裝。修改檔無 lint warning；135 個既有 warning、0 serious。
- 分享修正階段的本地回歸 25／25 exit 0。當時完整 27 tests 依 `CLAUDE.md` 僅重跑 1 次，結果為 25／27 通過；兩個既有農業部 API tests 各 15 秒 timeout，exit 65／`TEST_FAILED`。`collect-test-diagnostics` 僅關閉失敗診斷收集以避免卡住，未修改測試內容。
- 使用者實機：App→備忘錄完整動物文案、電話地址、可點 HTTPS 與正確 detail PASS；App→LINE 新分享文案完整，冷／暖啟動直達正確 detail PASS。舊 snapshot 尚無既有實機連結，維持未驗證。
- 後續 API 測試修正後，完整 `BringAPetHomeTests` 27/27 通過、generic iOS build exit 0，無新增 lint warning（135 個既有 warning、0 serious），達 `IMPLEMENTATION_COMPLETE`；詳見 [API 測試診斷與修正](2026-11-18-api-test-timeout.md)。這是既有驗證結果，本次僅修文件，未重跑測試或 build。未 commit，亦未達 `MERGE_READY`。
