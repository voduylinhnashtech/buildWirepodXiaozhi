#!/bin/bash

# Script cài đặt dependencies cho build WirePod Windows

echo "=== Cài đặt Dependencies cho Build WirePod Windows ==="
echo ""
echo "Script này sẽ cài đặt các packages sau:"
echo "  - mingw-w64 (cross-compiler cho Windows)"
echo "  - mingw-w64-tools (windres, etc.)"
echo "  - autotools-dev, automake, autoconf, libtool (để build OGG/Opus)"
echo "  - build-essential (gcc, make, etc.)"
echo ""
read -p "Bạn có muốn tiếp tục? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Đã hủy."
    exit 1
fi

echo ""
echo "Đang cài đặt dependencies..."
echo ""

sudo apt update && sudo apt install -y \
    mingw-w64 \
    mingw-w64-tools \
    build-essential \
    autotools-dev \
    automake \
    autoconf \
    libtool \
    pkg-config

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Cài đặt thành công!"
    echo ""
    echo "Bây giờ bạn có thể chạy:"
    echo "  cd /home/linh/demoxiaozhi/buildWirepodXiaozhi/windows"
    echo "  ./build.sh v1.0.0"
else
    echo ""
    echo "❌ Có lỗi xảy ra khi cài đặt!"
    exit 1
fi

