#!/bin/bash

PY_VERSION=$1

if [ -z "$PY_VERSION" ]; then
    echo "❌ 错误: 请指定 Python 版本 (例如 3.10.12)"
    exit 1
fi

WORK_DIR="python_download_temp"
PACKAGES_DIR="$WORK_DIR/packages"
SYS_PKGS_DIR="$WORK_DIR/sys_packages"
rm -rf "$WORK_DIR"
mkdir -p "$PACKAGES_DIR" "$SYS_PKGS_DIR"

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

if [ "$OS_TYPE" == "redhat" ]; then
    RPM_LIST="gcc make zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel libffi-devel xz-devel"
    
    if ! command -v yumdownloader &> /dev/null; then
        yum install -y yum-utils
    fi

    yumdownloader --resolve --destdir="$SYS_PKGS_DIR" $RPM_LIST

elif [ "$OS_TYPE" == "debian" ]; then
    DEB_LIST="build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev libbz2-dev liblzma-dev tk-dev"
    
    apt-get clean
    cd "$SYS_PKGS_DIR"
    for pkg in $DEB_LIST; do
        apt-get download "$pkg"
    done
    cd - > /dev/null
fi

PY_MAJOR_MINOR=$(echo "$PY_VERSION" | cut -d. -f1,2)
SOURCE_URL="https://www.python.org/ftp/python/${PY_VERSION}/Python-${PY_VERSION}.tgz"

if command -v wget &> /dev/null; then
    wget -P "$WORK_DIR" "$SOURCE_URL"
else
    curl -o "$WORK_DIR/Python-${PY_VERSION}.tgz" "$SOURCE_URL"
fi

if [ -s "requirements.txt" ]; then
    pip download \
        -r requirements.txt \
        --dest "$PACKAGES_DIR" \
        --python-version "$PY_MAJOR_MINOR" \
        --platform manylinux2014_x86_64 \
        --implementation cp \
        --abi "cp$(echo $PY_MAJOR_MINOR | tr -d .)" \
        --only-binary=:all: || \
    pip download \
        -r requirements.txt \
        --dest "$PACKAGES_DIR" \
        --python-version "$PY_MAJOR_MINOR"
        
    cp requirements.txt "$WORK_DIR/"
fi

echo "$OS_TYPE" > "$WORK_DIR/os_type.txt"

TAR_NAME="python_package.tar"
tar -cvf "$TAR_NAME" -C "$WORK_DIR" .
rm -rf "$WORK_DIR"

echo "✅ 完成！请将 $TAR_NAME 复制到离线机器。"