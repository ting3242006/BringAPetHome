# Universal Links Hosting 與實機驗證

正式動物網址：`https://bringapethome.web.app/animal/{animalId}`。
實際分享提供一份完整文字，內含唯一 HTTPS 連結並附 `openExternalBrowser=1`，供 LINE 與備忘錄接收；canonical URL 維持不帶 query。
Firebase project/site：`bringapethome`。App Store：`1536547532`。

## 2026-11-18 驗證紀錄

- Generic iOS build：exit 0；SwiftLint 135 個既有 warning、0 serious，本次無新增 warning。
- Hosting：4/4 通過，Firebase 正式部署 exit 0。
- 正式動物頁與 AASA 皆回 200、無轉址；AASA `Content-Type` 為 `application/json`，本地／正式／Apple CDN JSON 相符。
- 已檢查 390px 手機版、1440px 桌面版 fallback，以及有效／無效 ID 畫面。
- 真實單筆政府 API 查詢 `475138` 回 200，且只回傳 1 筆 matching 動物資料。
- 已在 Ting’s iPhone 核對新簽署 App 的 application-identifier、Associated Domains、profile 與裝置資格，並完成安裝。
- 使用者實機確認：備忘錄連結冷／暖啟動進入正確詳細頁；App 分享至備忘錄文字完整、連結可點且正確開啟；App 分享至 LINE 文案完整、冷／暖啟動直接進入正確詳細頁。LINE fallback 的手動「在 App 中查看」（無 snapshot Scheme）暖啟動亦通過。
- 尚待實機驗證：未安裝時的下載流程、舊 snapshot 連結、無 snapshot 舊 Scheme 冷啟動、同一動物重複點擊、錯誤狀態與不合法輸入。
- Review 修正（App 端，Hosting 未重新部署）：查詢失敗提示在 UI 未就緒時每 0.3 秒重試、最多 10 次，新連結會取消舊重試；host 比對改為不分大小寫，path 維持嚴格。修正後完整 `BringAPetHomeTests` 26/26 通過，build 無新增 warning。
- 後續分享與 API 測試修正後，完整 `BringAPetHomeTests` 27/27 通過，generic iOS build exit 0、無新增 warning；詳見 [API 測試診斷與修正](../docs/superpowers/plans/2026-11-18-api-test-timeout.md)。歷史 26/26 紀錄保留。此次只整理文件，未重跑測試或 build。

## 本地驗證與部署

```bash
node --test hosting/tests/hosting.test.cjs
plutil -lint BringAPetHome/BringAPetHome.entitlements
firebase deploy --only hosting --project bringapethome
```

`firebase.json` 僅部署 `hosting/public`；AASA 位於 `.well-known`，不被 dotfile ignore 排除。`appAssociation: NONE` 使用手寫 AASA。沒有 Dynamic Links、Functions、額外 SDK 或網頁端 API 查詢。

部署後檢查（不可加 `-L` 掩蓋轉址）：

```bash
curl -i https://bringapethome.web.app/.well-known/apple-app-site-association
curl -i https://bringapethome.web.app/animal/443673
curl -i https://app-site-association.cdn-apple.com/a/v1/bringapethome.web.app
```

AASA 必須直接回 200、`Content-Type: application/json`，內容含 `J3XG5W7SR9.com.YiTing.BringAPetHome` 與 `/animal/*`。動物頁必須回 200，下載連結為 `https://apps.apple.com/app/id1536547532`。根目錄或無效 ID 不顯示開啟 App 按鈕；停用 JavaScript 仍可下載 App。

Team ID 與 bundle ID 已從專案設定與舊 archive 身分資料交叉檢查；本次新簽署成品已完成身分、entitlement 與 profile 核對，LINE／備忘錄實機關聯亦已通過。後續版本仍應依下列方式核對：在 Apple Developer 的 App Identifier 啟用 Associated Domains，使用包含該能力的 provisioning profile 簽署新版本。以 `codesign -d --entitlements :- /path/to/BringAPetHome.app` 核對新成品 `application-identifier` 與 AASA 相同，並含 `applinks:bringapethome.web.app`。若實際 App ID prefix 與 Team ID 不同，需修正 AASA 後重新部署。

## 實機測試清單與狀態（使用更新後的簽署 App）

請在個人測試裝置執行；不要為驗證而刪除含未備份資料的 App。

1. **未安裝**：在未安裝 App 的 iPhone，從 LINE 或備忘錄點擊完整 HTTPS URL。應看到繁中 fallback、正確動物編號及 App Store 下載連結；下載按鈕開啟正確 App Store 頁面。
2. **安裝後冷啟動（備忘錄已通過）**：先部署 AASA，再安裝新簽署版本；將 App 關閉，從備忘錄點擊目前 API 存在的動物連結，應直接進入該動物詳細頁。
3. **暖啟動／背景（切換不同動物已通過；同一動物重複點擊待測）**：App 已開啟或留在背景時，點另一隻動物連結，應轉到正確詳細頁；重點同一隻不重複 push。
4. **LINE 分享**：在動物詳細頁分享至 LINE，訊息應保留動物文字、收容所聯絡資訊與可點擊的 `https://bringapethome.web.app/animal/{id}`；收件端測試冷／暖啟動。若 LINE 內嵌瀏覽器停在 fallback，可手動點「在 App 中查看」或改以 Safari 開啟。
5. **備忘錄分享（已通過）**：由分享選單儲存至備忘錄，確認動物文字與可點擊 HTTPS URL 均存在，再點擊驗證進入 App。
6. **舊 Scheme**：點擊先前保存的 `bringapethome://animal/{id}` 與含 snapshot 的舊連結；snapshot 即使 API 無法連線仍應能顯示原動物。舊格式不改寫、不移除。
7. **錯誤狀態**：斷網且使用未載入動物 ID，或用不存在的正整數 ID，應顯示「無法開啟動物資料」及關閉按鈕。關閉後 App 正常可用。快速點擊 A/B 連結，A 的延遲結果不可覆蓋 B。
8. **不合法輸入**：非指定網域、HTTP、非正整數、額外路徑不應導航到動物詳情。

iOS 會快取 AASA。從備忘錄長按連結應可選擇在 App 或瀏覽器開啟；系統可能記住選擇。Safari 網址列直接輸入 URL，以及在同一網域內繼續瀏覽，不是驗證 App 自動開啟的方式。必要時在開發者設定的 Universal Links Diagnostics 檢查關聯；使用新部署 AASA 後重新安裝測試版取得更新（先備份資料）。

上述通過項目依本次簽章核對及使用者實機回報標記；其餘仍待執行，不因單元測試／build 成功而自動標記通過。舊 snapshot 連結目前只有單元測試證據，未取得既有連結做實機驗證。

參考：[Apple TN3155](https://developer.apple.com/documentation/technotes/tn3155-debugging-universal-links)、[Firebase Universal Links](https://firebase.google.com/support/guides/app-links-universal-links)。
