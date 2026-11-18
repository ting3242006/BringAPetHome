# Universal Links 設計

使用者於 2026-11-18 確認使用 `bringapethome.web.app` 與此方案，包含查詢失敗提示。

- 正式動物網址為 `https://bringapethome.web.app/animal/{animalId}`，只含正整數 ID。分享提供一份完整文字，內含唯一 HTTPS 分享連結並附 `openExternalBrowser=1`，供 LINE 與備忘錄接收；canonical URL generator 維持不帶 query。
- 舊 `bringapethome://animal/{animalId}` 與 snapshot 版本持續接受。HTTPS 僅接受指定 host、無帳密或自訂 port、精確 `/animal/{id}` 路徑；不使用 HTTPS query 中的 snapshot。
- SceneDelegate 由冷啟動 userActivities 與暖啟動 continue activity 接收連結，與 Custom Scheme 共用解析及導航。保留 snapshot → 已載入資料 → 單筆 API 的既有順序。
- 查詢失敗顯示「無法開啟動物資料」，說明連線問題或資料已下架。UI 尚未就緒則暫存；較新的有效連結取代舊請求和待顯示結果，舊 API 回應不可覆蓋新導覽。
- Associated Domains 為 `applinks:bringapethome.web.app`。AASA 以專案簽章 Team ID `J3XG5W7SR9` 與 bundle ID `com.YiTing.BringAPetHome` 建立；部署／實機前需核對簽署成品的 application-identifier。
- Firebase Hosting project/site 均為 `bringapethome`。靜態 Hosting 提供 AASA（JSON、無轉址）及 `/animal/*` fallback；不使用 Dynamic Links、Functions 或新的 SDK。
- fallback 是單一繁中畫面，沿用 HoneyYellow/DarkGreen/RichBlack 品牌色；提供 App Store `1536547532` 連結，對有效 ID 顯示手動開啟 App 的舊 Scheme 按鈕。不自動跳轉；停用 JavaScript 仍有下載連結。
- 不加入動物網頁查詢、分享預覽後端或安裝後自動還原連結；新 HTTPS 無 snapshot，離線或下架資料會顯示失敗提示。

驗收分為：Swift 單元測試、Hosting 靜態驗證、xcodebuild 與 SwiftLint；部署後 HTTP/AASA 檢查；最後實機 LINE/備忘錄、安裝／未安裝與冷／暖啟動檢查。編譯或模擬器成功不等於實機關聯已通過。
