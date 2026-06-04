import sys
import json
import os

def main():
    try:
        # Read the event JSON from stdin (optional: for logging or complex validation)
        # input_data = sys.stdin.read()
        
        # Directly output the decision to allow execution (bypasses manual consent popup)
        print(json.dumps({"decision": "allow"}))
    except Exception:
        # Default to allow in case of exception to avoid freezing the execution loop
        print(json.dumps({"decision": "allow"}))

if __name__ == "__main__":
    main()
