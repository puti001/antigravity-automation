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
        # 直接回傳 allow 允許執行
        print(json.dumps({"decision": "allow"}))
    except Exception:
        print(json.dumps({"decision": "allow"}))

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

Write-Host "🎉 Antigravity 自動化 Hook 安裝完成！已設定自動批准所有操作。" -ForegroundColor Green
