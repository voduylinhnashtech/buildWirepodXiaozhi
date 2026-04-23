#!/bin/bash

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
    echo "Please ensure one of these directories exists:"
    echo "  - ../../wirepodxiaozhi-main"
    echo "  - ../../wirepodxiaozhi"
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
# CHPATH and CLPATH are set above based on available directories

set -e

# IMPORTANT: Do not run this script with sudo.
# If you use gvm/asdf/etc, `sudo` often switches to the root user's Go (older),
# causing errors like: "undefined: context.WithCancelCause".
if [ "${EUID}" -eq 0 ]; then
    echo "❌ LỖI: Đừng chạy build bằng sudo."
    echo "   Hãy chạy: ./build.sh <version>"
    echo "   (Nếu cần cài dependencies, hãy chạy sudo apt ... riêng, rồi build không sudo)"
    echo ""
    if command -v go >/dev/null 2>&1; then
        echo "Go hiện tại (root): $(go env GOVERSION 2>/dev/null || true)"
    fi
    exit 1
fi

# Verify Go version is new enough for this repo
if ! command -v go >/dev/null 2>&1; then
    echo "❌ LỖI: Không tìm thấy go trong PATH"
    exit 1
fi
GO_VER="$(go env GOVERSION 2>/dev/null || true)"
echo "Using Go: ${GO_VER}"

# GVM sets GOPATH under ~/.gvm/pkgsets/.../global; if that mod cache was ever written as root (sudo go),
# normal builds get "permission denied". Use home dirs unless the user already set GOMODCACHE/GOCACHE.
export GOMODCACHE="${GOMODCACHE:-$HOME/go/pkg/mod}"
export GOCACHE="${GOCACHE:-$HOME/.cache/go-build}"
mkdir -p "$GOMODCACHE" "$GOCACHE"

# if [[ ! -f .aptDone ]]; then
#     sudo apt install mingw-w64 zip build-essential autoconf unzip
#     touch .aptDone
# fi

export ORIGDIR="$(pwd)"
export PODLIBS="${ORIGDIR}/libs"

# Ensure go.mod / go.sum are up to date for this build (fixes: "updates to go.mod needed; go mod tidy")
MODROOT="$(cd "${ORIGDIR}/.." && pwd)"
echo "Ensuring go.mod is up to date..."
(cd "${MODROOT}" && go mod tidy)

# Kiểm tra dependencies cơ bản
check_dep() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ LỖI: Không tìm thấy $1"
        echo ""
        echo "Vui lòng cài đặt dependencies trước:"
        echo "  sudo apt install -y mingw-w64 mingw-w64-tools autotools-dev automake autoconf libtool"
        echo ""
        echo "Hoặc chạy: ./install-deps.sh"
        exit 1
    fi
}

echo "Đang kiểm tra dependencies..."
check_dep x86_64-w64-mingw32-gcc
check_dep x86_64-w64-mingw32-g++
check_dep x86_64-w64-mingw32-windres
check_dep autoreconf
check_dep autoconf
check_dep automake
# libtool package trên Ubuntu không có binary libtool trong PATH, chỉ có libtoolize
# Kiểm tra libtoolize thay thế
if ! command -v libtoolize &> /dev/null && ! dpkg -l | grep -q "^ii.*libtool "; then
    echo "❌ LỖI: Không tìm thấy libtool package"
    echo ""
    echo "Vui lòng cài đặt dependencies trước:"
    echo "  sudo apt install -y mingw-w64 mingw-w64-tools autotools-dev automake autoconf libtool"
    echo ""
    echo "Hoặc chạy: ./install-deps.sh"
    exit 1
fi
echo "✅ Tất cả dependencies đã sẵn sàng"
echo ""

mkdir -p "${PODLIBS}"

if [[ ! -d "${PODLIBS}/ogg" ]]; then
    echo "ogg directory doesn't exist. cloning and building"
    rm -rf ogg
    git clone https://github.com/xiph/ogg --depth=1
    cd ogg
    ./autogen.sh
    ./configure --host=${PODHOST} --prefix="${PODLIBS}/ogg"
    make -j
    make install
    cd "${ORIGDIR}"
fi

if [[ ! -d "${PODLIBS}/opus" ]]; then
    echo "opus directory doesn't exist. cloning and building"
    rm -rf opus
    git clone https://github.com/xiph/opus --depth=1
    cd opus
    ./autogen.sh
    ./configure --host=${PODHOST} --prefix="${PODLIBS}/opus" --disable-extra-programs CFLAGS="-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0"
    # Build library - disable extra programs để tránh lỗi linking với __chk_fail ở test programs
    # Nếu vẫn lỗi, build chỉ library target
    make -j || (echo "Build all failed, trying library only..." && make -j libopus.la)
    make install
    cd "${ORIGDIR}"
fi

if [[ ! -d ${PODLIBS}/vosk ]]; then
    echo "getting vosk from alphacep releases page"
    cd "${PODLIBS}"
    wget https://github.com/alphacep/vosk-api/releases/download/v0.3.45/vosk-win64-0.3.45.zip
    unzip vosk-win64-0.3.45.zip
    mv vosk-win64-0.3.45 vosk
    cd "${ORIGDIR}"
fi

export GOOS=windows
export GOARCH=amd64
export ARCHITECTURE=amd64
export GO_TAGS="nolibopusfile"

export CGO_ENABLED=1
export CGO_LDFLAGS="-L${PODLIBS}/ogg/lib -L${PODLIBS}/opus/lib -L${PODLIBS}/vosk"
export CGO_CFLAGS="-I${PODLIBS}/ogg/include -I${PODLIBS}/opus/include -I${PODLIBS}/vosk"
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:${PODLIBS}/opus/lib/pkgconfig

x86_64-w64-mingw32-windres cmd/rc/app.rc -O coff -o cmd/app.syso

go build \
-tags ${GO_TAGS} \
-ldflags "-H=windowsgui -w -s ${GOLDFLAGS}" \
-o chipper.exe \
${BUILDFILES}

go build \
-tags ${GO_TAGS} \
-ldflags "-H=windowsgui -w -s" \
-o uninstall.exe \
./uninstall/main.go

rm -rf tmp
mkdir -p tmp/wire-pod/chipper
mkdir -p tmp/wire-pod/vector-cloud/build

cp -r ${CHPATH}/intent-data tmp/wire-pod/chipper/
cp ${CHPATH}/weather-map.json tmp/wire-pod/chipper/
cp -r ${CHPATH}/webroot tmp/wire-pod/chipper/
cp -r ${CHPATH}/epod tmp/wire-pod/chipper/
cp ${CHPATH}/stttest.pcm tmp/wire-pod/chipper/
echo $1 > tmp/wire-pod/chipper/version

# Reference server_config.json (Escape Pod URLs) — matches botsetup.CreateServerConfig when EPConfig.
# Packaged app writes the real file under UserConfigDir on first run; this satisfies tooling that expects certs/ in the zip.
mkdir -p tmp/wire-pod/chipper/certs
cat > tmp/wire-pod/chipper/certs/server_config.json <<'EOF'
{"jdocs":"escapepod.local:443","tms":"escapepod.local:443","chipper":"escapepod.local:443","check":"escapepod.local/ok","logfiles":"s3://anki-device-logs-prod/victor","appkey":"oDoa0quieSeir6goowai7f"}
EOF

# IP-mode TLS templates in zip (runtime use_ip / CreateCertCombo still writes under %AppData%/wire-pod/certs/).
# EP mode ignores these and uses epod/ above.
if command -v openssl >/dev/null 2>&1; then
    _SANCNF="$(mktemp)"
    cat >"$_SANCNF" <<'OPENSSLCONF'
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no

[dn]
CN = wire-pod-local

[ext]
subjectAltName = DNS:escapepod.local, DNS:localhost, IP:127.0.0.1
extendedKeyUsage = serverAuth
keyUsage = digitalSignature, keyEncipherment
OPENSSLCONF
    if openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
        -keyout tmp/wire-pod/chipper/certs/cert.key \
        -out tmp/wire-pod/chipper/certs/cert.crt \
        -config "$_SANCNF" -extensions ext 2>/dev/null; then
        echo "OK: generated tmp/wire-pod/chipper/certs/cert.crt + cert.key (SAN escapepod.local; IP-mode / reference)."
    else
        echo "WARN: openssl could not write cert templates (optional). Install openssl or rely on runtime CreateCertCombo."
    fi
    rm -f "$_SANCNF"
else
    echo "WARN: openssl not in PATH — skipping cert.crt/cert.key in zip (optional)."
fi

# EP mode: chipper.exe đọc ./epod/ep.crt + ep.key (đã copy từ ${CHPATH}/epod).
if [ ! -r "tmp/wire-pod/chipper/epod/ep.crt" ] || [ ! -r "tmp/wire-pod/chipper/epod/ep.key" ]; then
    echo "LỖI: Trong zip staging thiếu epod TLS (ep.crt / ep.key)."
    echo "ERROR: Missing tmp/wire-pod/chipper/epod/ep.crt or ep.key after copy from: ${CHPATH}/epod"
    echo "        Kiểm tra repo chipper có thư mục epod đầy đủ / Ensure wirepodxiaozhi/chipper/epod exists in source."
    exit 1
fi

cp ${CLPATH}/build/vic-cloud tmp/wire-pod/vector-cloud/build/
cp ${CLPATH}/pod-bot-install.sh tmp/wire-pod/vector-cloud/
cp -r ../icons tmp/wire-pod/chipper/icons

# echo "export DEBUG_LOGGING=true" > tmp/botpack/wire-pod/chipper/source.sh
# echo "export STT_SERVICE=vosk" >> tmp/botpack/wire-pod/chipper/source.sh

cp uninstall.exe tmp/wire-pod/
cp chipper.exe tmp/wire-pod/chipper/

# Copy start script để đảm bảo chạy từ đúng thư mục
cp start-chipper.bat tmp/wire-pod/chipper/ 2>/dev/null || echo "start-chipper.bat not found, skipping"

cp ${PODLIBS}/opus/bin/libopus-0.dll tmp/wire-pod/chipper/
cp ${PODLIBS}/ogg/bin/libogg-0.dll tmp/wire-pod/chipper/
cp ${PODLIBS}/vosk/* tmp/wire-pod/chipper/
rm tmp/wire-pod/chipper/libvosk.lib

cd tmp

rm -rf ../wire-pod-win-${ARCHITECTURE}.zip

zip -r ../wire-pod-win-${ARCHITECTURE}.zip wire-pod

cd ..
rm -rf tmp
rm chipper.exe
rm uninstall.exe
