# Antigravity Automation Hooks (自動化指令核准工具)

這是一個用於 **Google Antigravity** / **Gemini Agent** 開發環境的自動化輔助工具。

透過註冊 `PreToolUse` 生命週期 Hook，本工具會自動批准 (Auto-Approve) 絕大多數的終端機指令（如 `git`、`npm`、`python` 等）與檔案存取操作，免去在開發過程中頻繁手動點擊「同意 (Consent / Approve)」確認彈窗的困擾。

---

## ⚙️ 模式選擇：極速模式 vs 開發者攔截模式

在 Antigravity 中，若想達到過程免確認的自動化，共有以下兩種途徑可供選擇：

### 🏎️ 途徑一：極速模式 (Turbo Mode)
這是 Antigravity 軟體介面內建的全域開關：
- **設定方式**：進入專案的 `Project Settings` ➔ `Agent Setting` ➔ 將模式切換為 `Turbo mode` ➔ 在 `Behavior` 中選擇 `Always proceed`。
- **優點**：設定極為簡便，滑鼠點選即可。
- **缺點**：
  - **無條件盲信（高風險）**：屬於全開或全關的二分法。AI 執行任何高危險指令（如 `rm -rf`）或讀取敏感私鑰檔案時，系統均不會進行安全防護或警告。
  - **缺乏稽核日誌**：背景執行無任何日誌留存，使用者無法追蹤 AI 跑了哪些後台命令。
  - **環境限制**：在某些受管制或安全強度高的工作站中，此 UI 設定可能會被環境原則強制停用。

### 🛡️ 途徑二：開發者攔截模式 (Developer Interception Mode) - 本專案所採用
透過註冊 `PreToolUse` Hook，由自訂 Python 腳本（`auto_approve.py`）智慧審查每一次的工具調用：
- **運作方式**：每次 AI 呼叫工具前，先由本機腳本過濾，僅在判定安全時才自動放行，否則退回手動確認。
- **優點**：
  - **具備可程式化防禦（智慧安全）**：本腳本已主動過濾敏感檔案（如 `.env`、`id_rsa`）及高危指令（如 `rm`、`del`），遇險自動轉回彈窗警告。
  - **自動留存日誌**：每次工具調用細節都會自動附加寫入 `hook_log.txt` 中，方便開發者進行後續排查與追蹤。
  - **AI 助理友善**：支援別人的 AI 助理一鍵安裝，不需人工用滑鼠在軟體介面中點選選單。
- **缺點**：首次安裝需透過 PowerShell 執行安裝指令或交由 AI 處理。

---

## ⚡ 快速安裝 (PowerShell)

在 Windows 開啟 PowerShell，並貼上執行以下指令即可完成自動安裝：

```powershell
irm "https://raw.githubusercontent.com/puti001/antigravity-automation/main/install.ps1" | iex
```

> **說明**：安裝程式會自動偵測您的用戶目錄，並在 `~/.gemini/config/` 下建立對應的 `hooks.json` 以及自動放行腳本 `plugins/custom-commands/auto_approve.py`。

---

## 🤖 AI Agent 自動部署引導 (For AI Assistants)

如果你是協助使用者設定環境的 AI 助理（如 Antigravity 或 Claude Code），請直接讀取此區塊，並使用你的檔案寫入工具幫使用者完成部署，無需讓使用者手動執行 PowerShell：

1. **確定路徑**：找到使用者主目錄下的 `~/.gemini/config/` (Windows 為 `C:/Users/<Username>/.gemini/config/`)。
2. **寫入放行腳本**：建立 `plugins/custom-commands/auto_approve.py`，內容如下：
   ```python
   import sys
   import json
   import os

   def main():
       try:
           input_data = sys.stdin.read()
           if not input_data:
               print(json.dumps({"decision": "allow"}))
               return
           event_data = json.loads(input_data)
           
           # 紀錄日誌
           log_dir = r"C:\Users\<Username>\.gemini\antigravity\scratch"
           if os.path.exists(log_dir):
               with open(os.path.join(log_dir, "hook_log.txt"), "a", encoding="utf-8") as f:
                   f.write(json.dumps(event_data, ensure_ascii=False) + "\n")
           
           tool_call = event_data.get("toolCall", {})
           tool_name = tool_call.get("name", "")
           args = tool_call.get("args", {})
           
           # 1. 阻擋敏感檔案存取
           sensitive_files = [".env", ".npmrc", ".git-credentials", "id_rsa"]
           if tool_name in ("read_file", "write_file", "replace_file_content", "multi_replace_file_content"):
               target_path = args.get("TargetFile", "").lower()
               if any(sf in target_path for sf in sensitive_files):
                   print(json.dumps({"decision": "ask"}))
                   return
                   
           # 2. 阻擋危險命令
           if tool_name == "run_command":
               cmd = args.get("CommandLine", "").lower()
               dangerous_cmds = ["rm ", "del ", "format ", "mkfs", "rd "]
               if any(dc in cmd for dc in dangerous_cmds):
                   print(json.dumps({"decision": "ask"}))
                   return
                   
           print(json.dumps({"decision": "allow"}))
       except Exception:
           print(json.dumps({"decision": "ask"}))

   if __name__ == "__main__":
       main()
   ```
3. **寫入配置**：建立或覆蓋 `hooks.json`，內容如下：
   ```json
   {
     "hooks": {
       "PreToolUse": [
         {
           "matcher": ".*",
           "hooks": [
             {
               "type": "command",
               "command": "python C:/Users/<Username>/.gemini/config/plugins/custom-commands/auto_approve.py"
             }
           ]
         }
       ]
     }
   }
   ```
   *(請務必將 `<Username>` 替換為當前使用者的系統帳號名稱，路徑中的斜線一律使用正斜線 `/`)*

---

## 🛠️ 手動安裝步驟

若您不想使用一鍵安裝，亦可手動進行配置：

1. **建立自動放行腳本**
   在 `C:\Users\<您的用戶名>\.gemini\config\plugins\custom-commands\` 目錄下建立 `auto_approve.py` 檔案，代碼內容請參考上方的【AI Agent 自動部署引導】。

2. **註冊 Hook**
   在 `C:\Users\<您的用戶名>\.gemini\config\` 目錄下建立或修改 `hooks.json` 檔案：
   ```json
   {
     "hooks": {
       "PreToolUse": [
         {
           "matcher": ".*",
           "hooks": [
             {
               "type": "command",
               "command": "python C:/Users/<您的用戶名>/.gemini/config/plugins/custom-commands/auto_approve.py"
             }
           ]
         }
       ]
     }
   }
   ```
   *(注意：請將路徑中的 `<您的用戶名>` 替換為您系統的實際使用者名稱，且路徑分隔符必須使用正斜線 `/`)*

---

## 🛑 解除安裝 (Uninstall)

若要恢復預設的確認提示，請在 PowerShell 執行以下指令移除設定檔：

```powershell
Remove-Item -Path "$env:USERPROFILE\.gemini\config\hooks.json" -ErrorAction SilentlyContinue
Remove-Item -Path "$env:USERPROFILE\.gemini\config\plugins\custom-commands" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "已成功解除自動放行 Hook，恢復預設確認提示。" -ForegroundColor Yellow
```

---

## ⚠️ 安全警告 (Security Notice)

*   **信任環境專用**：雖然已加入敏感指令過濾，本工具仍會放行絕大多數操作。請確保您的開發環境以及您所下達的 AI 任務是安全、可信任的。
*   **避免生產環境使用**：請勿在存有極敏感資料的生產環境伺服器上開啟此自動放行設定。
