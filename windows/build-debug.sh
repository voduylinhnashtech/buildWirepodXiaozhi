#!/bin/bash

# Build version debug với console để xem log
# Sử dụng khi cần debug lỗi

export BUILDFILES="./cmd"

# Use wirepodxiaozhi-main or wirepodxiaozhi repo
if [ -d "../../wirepodxiaozhi-main" ]; then
    WP_COMMIT_HASH=$(cd ../../wirepodxiaozhi-main && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    export CHPATH="../../wirepodxiaozhi-main/chipper"
    export CLPATH="../../wirepodxiaozhi-main/vector-cloud"
    echo "Using wirepodxiaozhi-main directory"
elif [ -d "../../wirepodxiaozhi" ]; then
    WP_COMMIT_HASH=$(cd ../../wirepodxiaozhi && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    export CHPATH="../../wirepodxiaozhi/chipper"
    export CLPATH="../../wirepodxiaozhi/vector-cloud"
    echo "Using wirepodxiaozhi directory"
else
    echo "Error: wirepodxiaozhi-main or wirepodxiaozhi directory not found!"
    exit 1
fi
GOLDFLAGS="-X 'github.com/kercre123/wire-pod/chipper/pkg/vars.CommitSHA=${WP_COMMIT_HASH}'"

if [[ "$(uname -s)" == "Darwin" ]]; then
    export CC=x86_64-w64-mingw32-gcc
    export CXX=x86_64-w64-mingw32-g++
else
    export CC=/usr/bin/x86_64-w64-mingw32-gcc
    export CXX=/usr/bin/x86_64-w64-mingw32-g++
fi
export PODHOST=x86_64-w64-mingw32
export ARCHITECTURE=amd64

set -e

# IMPORTANT: Do not run this script with sudo (it may use root's old Go).
if [ "${EUID}" -eq 0 ]; then
    echo "❌ LỖI: Đừng chạy build-debug bằng sudo. Hãy chạy: ./build-debug.sh"
    if command -v go >/dev/null 2>&1; then
        echo "Go hiện tại (root): $(go env GOVERSION 2>/dev/null || true)"
    fi
    exit 1
fi

if ! command -v go >/dev/null 2>&1; then
    echo "❌ LỖI: Không tìm thấy go trong PATH"
    exit 1
fi
echo "Using Go: $(go env GOVERSION 2>/dev/null || true)"

# Tránh permission denied trên module cache GVM nếu từng có file thuộc root (xem build.sh).
export GOMODCACHE="${GOMODCACHE:-$HOME/go/pkg/mod}"
export GOCACHE="${GOCACHE:-$HOME/.cache/go-build}"
mkdir -p "$GOMODCACHE" "$GOCACHE"

export ORIGDIR="$(pwd)"
export PODLIBS="${ORIGDIR}/libs"

# Ensure go.mod / go.sum are up to date for this build
MODROOT="$(cd "${ORIGDIR}/.." && pwd)"
echo "Ensuring go.mod is up to date..."
(cd "${MODROOT}" && go mod tidy)

export GOOS=windows
export GOARCH=amd64
export GO_TAGS="nolibopusfile"

export CGO_ENABLED=1
export CGO_LDFLAGS="-L${PODLIBS}/ogg/lib -L${PODLIBS}/opus/lib -L${PODLIBS}/vosk"
export CGO_CFLAGS="-I${PODLIBS}/ogg/include -I${PODLIBS}/opus/include -I${PODLIBS}/vosk"
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:${PODLIBS}/opus/lib/pkgconfig

x86_64-w64-mingw32-windres cmd/rc/app.rc -O coff -o cmd/app.syso

# Build với console (KHÔNG có -H=windowsgui) để xem log
go build \
-tags ${GO_TAGS} \
-ldflags "-w -s ${GOLDFLAGS}" \
-o chipper-debug.exe \
${BUILDFILES}

echo ""
echo "✅ Build debug version thành công!"
echo "File: chipper-debug.exe (có console để xem log)"
echo ""
echo "Sử dụng:"
echo "  cd C:\\wire-pod\\chipper"
echo "  chipper-debug.exe"
echo ""

