# BringAPetHome（讓浪回家 BFFs）

台灣在地寵物認養 iOS app，串接政府收容所開放資料 API，提供瀏覽/篩選/收藏、送養貼文、聊天等功能。已上架 App Store（v1.1.1 → 開發中 v1.2.0）。技術架構、資料模型、SwiftLint 規則見 @AGENTS.md。

## 驗證指令（宣告任務完成前必跑）

完整 build log 很長，不要讓它直接進 context。寫檔後過濾：

```bash
LOG=$(mktemp -t bap-build).log
xcodebuild -project BringAPetHome.xcodeproj -scheme BringAPetHome \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build > "$LOG" 2>&1
echo "exit=$?"
grep -E "error:|BUILD (SUCCEEDED|FAILED)" "$LOG"

# 專案自身警告數（排除 SPM checkout 與 appintents 噪音）
grep "warning:" "$LOG" | grep -F "$PWD/BringAPetHome" \
  | grep -v "/SourcePackages/" | grep -v appintentsmetadataprocessor | sort -u | wc -l
```

規則：

- **必須加 `CODE_SIGNING_ALLOWED=NO`**。否則會卡在 `No "iOS Development" signing certificate` 而失敗，與程式碼無關。
- **不要 `sort` 過濾後的結果再 `head`**。`error:` 行會被重排到後面砍掉，造成「BUILD FAILED 但看不到錯誤」的假象。
- 失敗時去 `$LOG` 撈 `The following build commands failed` 附近，錯誤未必符合 `error:` 樣式。
- SPM 套件解析異常時，先跑 `xcodebuild -resolvePackageDependencies -project BringAPetHome.xcodeproj -scheme BringAPetHome`。
- `appintentsmetadataprocessor` 每行帶時間戳與 pid，`sort -u` 去不掉，會讓計數浮動，警告統計時要排除。

判準：`exit=0` 且出現 `** BUILD SUCCEEDED **`。

警告的判準要小心：**警告數只有在完整 build 後才可比較。** 增量 build 中已快取的 target 不會重新吐警告，同一份程式碼實測完整 build 是 175 條、增量 build 只有 139 條。所以：

- 完整 build（先 `xcodebuild clean`）→ 需重新建立 SPM 遷移後基準。遷移完成時的增量 build 實測為 **139 條 SwiftLint warning、0 serious**。
- 增量 build → 數字不可比，改成只檢查「你動過的檔案有沒有新警告」：

```bash
changed=$(git diff --name-only; git ls-files --others --exclude-standard)
if [ -n "$changed" ]; then
  grep "warning:" "$LOG" | grep -F -f <(printf '%s\n' "$changed") | sort -u
fi
```

`[ -n "$changed" ]` 這層防護不能省：macOS 的 BSD grep 在 `-f` 讀到空檔案時會匹配**全部**行（不是全不匹配），工作目錄乾淨時會把 175 條警告全報成你造成的。

### 單元測試（改動邏輯層時必跑）

```bash
LOG=$(mktemp -t bap-test).log
xcodebuild -project BringAPetHome.xcodeproj -scheme BringAPetHome \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.2' \
  -only-testing:BringAPetHomeTests CODE_SIGNING_ALLOWED=NO test > "$LOG" 2>&1
echo "exit=$?"
grep -E "Test Case .*(passed|failed)|TEST (SUCCEEDED|FAILED)" "$LOG"
```

判準：`exit=0` 且 `** TEST SUCCEEDED **`（實測 2026-07-12 連 5 輪綠）。

- **測試依賴外網**：兩個測試都實打農業部開放資料 API（`data.moa.gov.tw`）。斷網或 API 端掛掉會紅，與程式碼無關；紅的時候先 `curl` 該 URL 分辨是誰的鍋。timeout 5 秒、實測回應 2~5 秒，貼線——偶發逾時先重跑一次再下結論。
- 若報 `xcodebuild requires Xcode ... command line tools instance`：本機 xcode-select 曾被重設指向 CLT，先 `export DEVELOPER_DIR=/Applications/Xcode-27.0.0-Beta.2.app/Contents/Developer`（或請 user 用 sudo 重設 xcode-select）。

測試涵蓋極少（只有 2 個 API 連通性測試），UI/邏輯改動仍需對照 `FEATURE_TEST_PLAN.md` 說明受影響項目與手動驗證步驟。
