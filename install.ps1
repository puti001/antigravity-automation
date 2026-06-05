# 1. 定義設定檔目錄路徑
$configDir = "$env:USERPROFILE\.gemini\config"
$pluginDir = "$configDir\plugins\custom-commands"

# 2. 建立目錄（如果不存在）
if (-not (Test-Path $pluginDir)) {
    New-Item -ItemType Directory -Force -Path $pluginDir | Out-Null
}

# 3. 寫入 auto_approve.py
$pyContent = @'
import sys
import json
import os

def main():
    try:
        # 讀取系統傳入的 Tool Call 事件 JSON
        input_data = sys.stdin.read()
        if not input_data:
            print(json.dumps({"decision": "allow"}))
            return
            
        event_data = json.loads(input_data)
        
        # 記錄 Log 方便排查
        log_dir = r"C:\Users\clong\.gemini\antigravity\scratch"
        if os.path.exists(log_dir):
            with open(os.path.join(log_dir, "hook_log.txt"), "a", encoding="utf-8") as f:
                f.write(json.dumps(event_data, ensure_ascii=False) + "\n")
        
        # 解析工具呼叫內容
        tool_call = event_data.get("toolCall", {})
        tool_name = tool_call.get("name", "")
        args = tool_call.get("args", {})
        
        # 1. 可程式化防禦：阻擋/詢問敏感檔案存取
        sensitive_files = [".env", ".npmrc", ".git-credentials", "id_rsa"]
        if tool_name in ("read_file", "write_file", "replace_file_content", "multi_replace_file_content"):
            target_path = args.get("TargetFile", "").lower()
            if any(sf in target_path for sf in sensitive_files):
                print(json.dumps({"decision": "ask"}))
                return
                
        # 2. 可程式化防禦：阻擋/詢問高危險刪除/格式化命令
        if tool_name == "run_command":
            cmd = args.get("CommandLine", "").lower()
            dangerous_cmds = ["rm ", "del ", "format ", "mkfs", "rd "]
            if any(dc in cmd for dc in dangerous_cmds):
                print(json.dumps({"decision": "ask"}))
                return
                
        # 預設直接允許以達到最大自動化
        print(json.dumps({"decision": "allow"}))
        
    except Exception as e:
        print(json.dumps({"decision": "ask"}))

if __name__ == "__main__":
    main()
'@
Set-Content -Path "$pluginDir\auto_approve.py" -Value $pyContent -Encoding utf8

# 4. 寫入 hooks.json (使用正斜線防路徑跳脫錯誤)
$hooksPath = "$pluginDir\auto_approve.py".Replace('\', '/')
$jsonContent = @"
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "python $hooksPath"
          }
        ]
      }
    ]
  }
}
"@
Set-Content -Path "$configDir\hooks.json" -Value $jsonContent -Encoding utf8

Write-Host "🎉 Antigravity 自動化 Hook 安裝完成！已設定自動批准所有操作（含敏感指令安全防禦）。" -ForegroundColor Green
