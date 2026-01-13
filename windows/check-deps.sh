#!/bin/bash

# Script kiểm tra dependencies cần thiết để build WirePod cho Windows

echo "=== Kiểm tra Dependencies cho Build WirePod Windows ==="
echo ""

MISSING_DEPS=0

# Kiểm tra các lệnh cần thiết
check_command() {
    if command -v $1 &> /dev/null; then
        echo "✅ $1: OK"
        return 0
    else
        echo "❌ $1: KHÔNG TÌM THẤY"
        MISSING_DEPS=1
        return 1
    fi
}

# Kiểm tra Go
echo "1. Kiểm tra Go:"
if command -v go &> /dev/null; then
    GO_VERSION=$(go version | awk '{print $3}')
    echo "   ✅ Go: $GO_VERSION"
    # Kiểm tra version >= 1.18
    GO_MAJOR=$(echo $GO_VERSION | sed 's/go//' | cut -d. -f1)
    GO_MINOR=$(echo $GO_VERSION | sed 's/go//' | cut -d. -f2)
    if [ "$GO_MAJOR" -gt 1 ] || ([ "$GO_MAJOR" -eq 1 ] && [ "$GO_MINOR" -ge 18 ]); then
        echo "   ✅ Go version >= 1.18: OK"
    else
        echo "   ⚠️  Go version < 1.18, cần nâng cấp"
        MISSING_DEPS=1
    fi
else
    echo "   ❌ Go: KHÔNG TÌM THẤY"
    MISSING_DEPS=1
fi
echo ""

# Kiểm tra MinGW
echo "2. Kiểm tra MinGW-w64:"
check_command x86_64-w64-mingw32-gcc
check_command x86_64-w64-mingw32-g++
check_command x86_64-w64-mingw32-windres
echo ""

# Kiểm tra Autotools
echo "3. Kiểm tra Autotools (cần để build OGG/Opus):"
check_command autoconf
check_command automake
check_command autoreconf
check_command libtool
check_command pkg-config
echo ""

# Kiểm tra các công cụ khác
echo "4. Kiểm tra các công cụ khác:"
check_command git
check_command wget
check_command unzip
check_command zip
check_command make
echo ""

# Kiểm tra thư mục source
echo "5. Kiểm tra thư mục source:"
if [ -d "../../wirepodxiaozhi-main" ]; then
    echo "   ✅ wirepodxiaozhi-main: Tìm thấy"
    if [ -d "../../wirepodxiaozhi-main/chipper" ]; then
        echo "   ✅ wirepodxiaozhi-main/chipper: Tìm thấy"
    else
        echo "   ❌ wirepodxiaozhi-main/chipper: KHÔNG TÌM THẤY"
        MISSING_DEPS=1
    fi
    if [ -d "../../wirepodxiaozhi-main/vector-cloud" ]; then
        echo "   ✅ wirepodxiaozhi-main/vector-cloud: Tìm thấy"
    else
        echo "   ❌ wirepodxiaozhi-main/vector-cloud: KHÔNG TÌM THẤY"
        MISSING_DEPS=1
    fi
elif [ -d "../../wirepodxiaozhi" ]; then
    echo "   ✅ wirepodxiaozhi: Tìm thấy"
    if [ -d "../../wirepodxiaozhi/chipper" ]; then
        echo "   ✅ wirepodxiaozhi/chipper: Tìm thấy"
    else
        echo "   ❌ wirepodxiaozhi/chipper: KHÔNG TÌM THẤY"
        MISSING_DEPS=1
    fi
    if [ -d "../../wirepodxiaozhi/vector-cloud" ]; then
        echo "   ✅ wirepodxiaozhi/vector-cloud: Tìm thấy"
    else
        echo "   ❌ wirepodxiaozhi/vector-cloud: KHÔNG TÌM THẤY"
        MISSING_DEPS=1
    fi
else
    echo "   ❌ wirepodxiaozhi-main hoặc wirepodxiaozhi: KHÔNG TÌM THẤY"
    MISSING_DEPS=1
fi
echo ""

# Tổng kết
echo "=== KẾT QUẢ ==="
if [ $MISSING_DEPS -eq 0 ]; then
    echo "✅ Tất cả dependencies đã sẵn sàng! Bạn có thể chạy ./build.sh v1.0.0"
    exit 0
else
    echo "❌ Thiếu một số dependencies!"
    echo ""
    echo "Để cài đặt các dependencies còn thiếu, chạy:"
    echo ""
    echo "sudo apt update"
    echo "sudo apt install -y \\"
    echo "    mingw-w64 \\"
    echo "    mingw-w64-tools \\"
    echo "    zip \\"
    echo "    build-essential \\"
    echo "    autotools-dev \\"
    echo "    automake \\"
    echo "    autoconf \\"
    echo "    libtool \\"
    echo "    unzip \\"
    echo "    wget \\"
    echo "    git \\"
    echo "    golang-go \\"
    echo "    pkg-config"
    exit 1
fi

