#!/bin/bash

TAR_NAME="python_package.tar"
INSTALL_DIR="$(pwd)/python_env"
TEMP_DIR="temp_extract"

if [ ! -f "$TAR_NAME" ]; then
    echo "❌ 未找到 $TAR_NAME"
    exit 1
fi

rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"
tar -xvf "$TAR_NAME" -C "$TEMP_DIR"

OS_TYPE=$(cat "$TEMP_DIR/os_type.txt")
SYS_PKGS_DIR="$TEMP_DIR/sys_packages"

if [ "$EUID" -ne 0 ]; then
    echo "⚠️  警告: 安装系统包(rpm/deb)通常需要 root 权限。"
    read -p "是否尝试继续? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit 1; fi
else
    cd "$SYS_PKGS_DIR"
    
    if [ "$OS_TYPE" == "redhat" ]; then
        rpm -Uvh *.rpm --force --nodeps
    elif [ "$OS_TYPE" == "debian" ]; then
        dpkg -i *.deb
    fi
    cd ../..
fi

PY_SRC_TGZ=$(find "$TEMP_DIR" -name "Python-*.tgz" | head -n 1)
cd "$TEMP_DIR"
tar -xvf $(basename "$PY_SRC_TGZ")
PY_SRC_DIR=$(find . -maxdepth 1 -type d -name "Python-*" | head -n 1)

cd "$PY_SRC_DIR"

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
REQ_FILE="$TEMP_DIR/requirements.txt"
PKG_DIR="$TEMP_DIR/packages"

if [ -s "$REQ_FILE" ]; then
    "$INSTALL_DIR/bin/pip" install \
        --no-index \
        --find-links="$PKG_DIR" \
        -r "$REQ_FILE"
fi

rm -rf "$TEMP_DIR"

echo "🎉 全部完成！"
echo "激活环境: export PATH=$INSTALL_DIR/bin:\$PATH"