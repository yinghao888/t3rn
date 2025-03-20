#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/t3rn.sh"
LOGFILE="$HOME/executor/executor.log"
EXECUTOR_DIR="$HOME/executor"

# 检查是否以 root 用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以 root 用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到 root 用户，然后再次运行此脚本。"
    exit 1
fi

# 执行脚本函数
function execute_script() {
    # 检查 pm2 是否安装，如果没有安装则自动安装
    if ! command -v pm2 &> /dev/null; then
        echo "pm2 未安装，正在安装 pm2..."
        sudo npm install -g pm2
        if [ $? -eq 0 ]; then
            echo "pm2 安装成功。"
        else
            echo "pm2 安装失败，请检查 npm 配置。"
            exit 1
        fi
    else
        echo "pm2 已安装，继续执行。"
    fi

    # 检查 tar 是否安装，如果没有安装则自动安装
    if ! command -v tar &> /dev/null; then
        echo "tar 未安装，正在安装 tar..."
        # 假设使用的是基于 Debian/Ubuntu 的系统
        sudo apt-get update && sudo apt-get install -y tar
        if [ $? -eq 0 ]; then
            echo "tar 安装成功。"
        else
            echo "tar 安装失败，请检查包管理器配置。"
            exit 1
        fi
    else
        echo "tar 已安装，继续执行。"
    fi

    # 下载最新版本的文件
    echo "正在下载v53的 executor..."
    wget https://github.com/t3rn/executor-release/releases/download/v0.53.0/executor-linux-v0.53.0.tar.gz 

    # 检查下载是否成功
    if [ $? -eq 0 ]; then
        echo "下载成功。"
    else
        echo "下载失败，请检查网络连接或下载地址。"
        exit 1
    fi

    # 解压文件到当前目录
    echo "正在解压文件..."
    tar -xzf executor-linux-0.53.0.tar.gz

    # 检查解压是否成功
    if [ $? -eq 0 ]; then
        echo "解压成功。"
    else
        echo "解压失败，请检查 tar.gz 文件。"
        exit 1
    fi

    # 检查解压后的文件名是否包含 'executor'
    echo "正在检查解压后的文件或目录名称是否包含 'executor'..."
    if ls | grep -q 'executor'; then
        echo "检查通过，找到包含 'executor' 的文件或目录。"
    else
        echo "未找到包含 'executor' 的文件或目录，可能文件名不正确。"
        exit 1
    fi

    # 提示用户输入环境变量的值，给 EXECUTOR_MAX_L3_GAS_PRICE 设置默认值为 100
    read -p "请输入 EXECUTOR_MAX_L3_GAS_PRICE 的值 [默认 100]: " EXECUTOR_MAX_L3_GAS_PRICE
    EXECUTOR_MAX_L3_GAS_PRICE="${EXECUTOR_MAX_L3_GAS_PRICE:-100}"

    
    # 提示用户输入Alchemy的api
    read -p "KEY ALCHEMY: " KEYALCHEMY

    # 设置环境变量
    export ENVIRONMENT=testnet
    export LOG_LEVEL=debug
    export LOG_PRETTY=false
    export ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,unichain-sepolia,optimism-sepolia,l2rn'
    export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false
    export EXECUTOR_MAX_L3_GAS_PRICE="$EXECUTOR_MAX_L3_GAS_PRICE"

    # 新增的环境变量
    export EXECUTOR_PROCESS_BIDS_ENABLED=true
    export EXECUTOR_PROCESS_ORDERS_ENABLED=true
    export EXECUTOR_PROCESS_CLAIMS_ENABLED=true
    export RPC_ENDPOINTS='{
    "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
    "arbt": ["https://arb-sepolia.g.alchemy.com/v2/$KEYALCHEMY""],
    "bast": ["https://base-sepolia.g.alchemy.com/v2/$KEYALCHEMY"],
    "opst": ["https://opt-sepolia.g.alchemy.com/v2/$KEYALCHEMY"],
    "unit": ["https://unichain-sepolia.g.alchemy.com/v2/$KEYALCHEMY"]
    }'

    # 提示用户输入私钥
    read -p "请输入 PRIVATE_KEY_LOCAL 的值: " PRIVATE_KEY_LOCAL

    # 设置私钥变量
    export PRIVATE_KEY_LOCAL="$PRIVATE_KEY_LOCAL"

    # 删除压缩文件
    echo "删除压缩包..."
    rm executor-linux-*.tar.gz

    # 切换目录到 executor/bin
    echo "切换目录并准备使用 pm2 启动 executor..."
    cd ~/executor/executor/bin

    # 使用 pm2 启动 executor
    echo "通过 pm2 启动 executor..."
    pm2 start ./executor --name "executor" --log "$LOGFILE" --env NODE_ENV=testnet

    # 显示 pm2 进程列表
    pm2 list

    echo "executor 已通过 pm2 启动。"
