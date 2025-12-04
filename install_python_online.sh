#!/bin/bash

# =================================================================
# 脚本名称: install_python_online.sh
# 功能: 在联网环境下安装系统依赖，编译指定版本的 Python，并安装 requirements.txt
# 用法: sh install_python_online.sh <python_version>
# 示例: sh install_python_online.sh 3.10.12
# =================================================================

PY_VERSION=$1
INSTALL_DIR="$(pwd)/python_env"
WORK_DIR="python_build_temp"

if [ -z "$PY_VERSION" ]; then
    echo "❌ 错误: 请指定 Python 版本 (例如 3.10.12)"
    exit 1
fi

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

if [ ! -f "requirements.txt" ]; then
    touch requirements.txt
fi

OS_TYPE=""
if [ -f /etc/redhat-release ]; then
    OS_TYPE="redhat"
elif [ -f /etc/lsb-release ] || [ -f /etc/debian_version ]; then
    OS_TYPE="debian"
else
    echo "❌ 不支持的操作系统类型，仅支持 CentOS/RHEL 或 Ubuntu/Debian。"
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    SUDO_CMD="sudo"
else
    SUDO_CMD=""
fi

if [ "$OS_TYPE" == "redhat" ]; then
    RPM_LIST="gcc make zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel libffi-devel xz-devel wget"
    $SUDO_CMD yum install -y $RPM_LIST

elif [ "$OS_TYPE" == "debian" ]; then
    DEB_LIST="build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev libbz2-dev liblzma-dev tk-dev wget"
    $SUDO_CMD apt-get update
    $SUDO_CMD apt-get install -y $DEB_LIST
fi

SOURCE_URL="https://www.python.org/ftp/python/${PY_VERSION}/Python-${PY_VERSION}.tgz"

echo "⬇️  正在下载 Python 源码..."
if command -v wget &> /dev/null; then
    wget -P "$WORK_DIR" "$SOURCE_URL"
else
    curl -o "$WORK_DIR/Python-${PY_VERSION}.tgz" "$SOURCE_URL"
fi

cd "$WORK_DIR"
tar -xvf "Python-${PY_VERSION}.tgz"
cd "Python-${PY_VERSION}"

./configure --prefix="$INSTALL_DIR" --enable-optimizations

CPU_CORES=$(nproc)
make -j"$CPU_CORES"
make install

if [ ! -f "$INSTALL_DIR/bin/python3" ]; then
    echo "❌ Python 编译安装失败。"
    exit 1
fi

ln -sf "$INSTALL_DIR/bin/python3" "$INSTALL_DIR/bin/python"
ln -sf "$INSTALL_DIR/bin/pip3" "$INSTALL_DIR/bin/pip"

cd ../..
rm -rf "$WORK_DIR"

if [ -s "requirements.txt" ]; then
    "$INSTALL_DIR/bin/pip" install -r requirements.txt
fi

echo "🎉 全部完成！"
echo "Python 已安装在: $INSTALL_DIR"
echo "激活环境: export PATH=$INSTALL_DIR/bin:\$PATH"