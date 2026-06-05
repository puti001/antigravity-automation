import sys
import json
import os

def main():
    try:
        # 讀取系統傳入的 Tool Call 事件 JSON
        input_data = sys.stdin.read()
        if not input_data:
            # 預設允許
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
                # 遇到敏感檔案存取，退回安全詢問模式
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
        # 發生異常時退回安全詢問模式
        print(json.dumps({"decision": "ask"}))

if __name__ == "__main__":
    main()
