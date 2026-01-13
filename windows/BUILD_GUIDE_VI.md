# Hướng Dẫn Build WirePod cho Windows

## Yêu Cầu Hệ Thống

### 1. Hệ điều hành
- Linux (Ubuntu/Debian) hoặc macOS để cross-compile
- Hoặc Windows với WSL2 (Windows Subsystem for Linux)

### 2. Công cụ cần thiết

#### Trên Linux:
```bash
sudo apt update
sudo apt install -y \
    mingw-w64 \
    mingw-w64-tools \
    zip \
    build-essential \
    autotools-dev \
    automake \
    autoconf \
    libtool \
    unzip \
    wget \
    git \
    golang-go \
    pkg-config
```

#### Trên macOS:
```bash
# Cài đặt Homebrew nếu chưa có
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Cài đặt các công cụ
brew install mingw-w64 go git autoconf automake libtool pkg-config
```

### 3. Go Version
- Go 1.18 hoặc cao hơn
- Kiểm tra: `go version`

## Cấu Trúc Thư Mục

Đảm bảo cấu trúc thư mục như sau:
```
demoxiaozhi/
├── buildWirepodXiaozhi/
│   └── windows/
│       ├── build.sh
│       ├── build-installer.sh
│       └── ...
└── wirepodxiaozhi/  (hoặc wirepodxiaozhi-main/)
    ├── chipper/
    └── vector-cloud/
```

## Các Bước Build

### Bước 1: Chuẩn bị môi trường

1. **Clone repository nếu chưa có:**
```bash
cd /home/linh/demoxiaozhi
# Đảm bảo có thư mục wirepodxiaozhi hoặc wirepodxiaozhi-main
```

2. **Kiểm tra Go environment:**
```bash
go env
# Đảm bảo GOPATH và GOROOT được set đúng
```

### Bước 2: Build ứng dụng chính (chipper.exe)

1. **Di chuyển vào thư mục windows:**
```bash
cd /home/linh/demoxiaozhi/buildWirepodXiaozhi/windows
```

2. **Chạy script build:**
```bash
# Cú pháp: ./build.sh <version>
# Ví dụ:
./build.sh v1.0.0
# hoặc
./build.sh 1.0.0
```

**Script sẽ tự động:**
- ✅ Clone và build thư viện OGG (nếu chưa có)
- ✅ Clone và build thư viện Opus (nếu chưa có)
- ✅ Download Vosk API từ GitHub releases
- ✅ Cross-compile Go code cho Windows (amd64)
- ✅ Tạo resource file (.syso) từ app.rc
- ✅ Build chipper.exe và uninstall.exe
- ✅ Đóng gói tất cả files vào ZIP

3. **Kết quả:**
   - File ZIP: `wire-pod-win-amd64.zip`
   - Chứa: chipper.exe, uninstall.exe, DLLs, và tất cả resources

### Bước 3: Build Windows Installer (Tùy chọn)

1. **Chạy script build installer:**
```bash
# Cú pháp: ./build-installer.sh <version>
./build-installer.sh v1.0.0
```

2. **Kết quả:**
   - File: `WirePodInstaller-v1.0.0.exe`
   - Installer GUI với Fyne framework

## Chi Tiết Quá Trình Build

### 1. Build Native Libraries

Script tự động build các thư viện native:

#### OGG Library
```bash
git clone https://github.com/xiph/ogg --depth=1
cd ogg
./autogen.sh
./configure --host=x86_64-w64-mingw32 --prefix="${PODLIBS}/ogg"
make -j
make install
```

#### Opus Library
```bash
git clone https://github.com/xiph/opus --depth=1
cd opus
./autogen.sh
./configure --host=x86_64-w64-mingw32 --prefix="${PODLIBS}/opus"
make -j
make install
```

#### Vosk API
```bash
# Download từ GitHub releases
wget https://github.com/alphacep/vosk-api/releases/download/v0.3.45/vosk-win64-0.3.45.zip
unzip vosk-win64-0.3.45.zip
```

### 2. Cross-Compile Go Code

Environment variables được set:
```bash
export GOOS=windows
export GOARCH=amd64
export CGO_ENABLED=1
export CC=x86_64-w64-mingw32-gcc
export CXX=x86_64-w64-mingw32-g++
export CGO_LDFLAGS="-L${PODLIBS}/ogg/lib -L${PODLIBS}/opus/lib -L${PODLIBS}/vosk"
export CGO_CFLAGS="-I${PODLIBS}/ogg/include -I${PODLIBS}/opus/include -I${PODLIBS}/vosk"
```

Build commands:
```bash
# Build resource file
x86_64-w64-mingw32-windres cmd/rc/app.rc -O coff -o cmd/app.syso

# Build chipper.exe
go build \
  -tags nolibopusfile \
  -ldflags "-H=windowsgui -w -s ${GOLDFLAGS}" \
  -o chipper.exe \
  ./cmd

# Build uninstall.exe
go build \
  -tags nolibopusfile \
  -ldflags "-H=windowsgui -w -s" \
  -o uninstall.exe \
  ./uninstall/main.go
```

### 3. Đóng Gói

Script tạo cấu trúc:
```
tmp/wire-pod/
├── chipper/
│   ├── chipper.exe
│   ├── intent-data/
│   ├── webroot/
│   ├── epod/
│   ├── libopus-0.dll
│   ├── libogg-0.dll
│   └── vosk files...
├── vector-cloud/
│   └── build/
│       └── vic-cloud
└── uninstall.exe
```

Sau đó zip lại thành `wire-pod-win-amd64.zip`

## Troubleshooting

### Lỗi: "mingw-w64 not found"
```bash
# Ubuntu/Debian
sudo apt install mingw-w64

# macOS
brew install mingw-w64
```

### Lỗi: "wirepodxiaozhi-main directory not found"
```bash
# Đảm bảo thư mục tồn tại ở cấp độ phù hợp
cd /home/linh/demoxiaozhi
ls -la wirepodxiaozhi/  # hoặc wirepodxiaozhi-main/
```

### Lỗi: "CGO compilation failed"
- Kiểm tra các thư viện native đã được build đúng
- Kiểm tra CGO_LDFLAGS và CGO_CFLAGS
- Đảm bảo các DLL files tồn tại

### Lỗi: "windres not found"
```bash
# Ubuntu/Debian
sudo apt install mingw-w64-tools

# macOS (đã có trong mingw-w64)
```

### Lỗi: "autoreconf: not found" hoặc "autogen.sh not found"
```bash
# Cài đặt autotools (bắt buộc để build OGG và Opus)
sudo apt install -y autotools-dev automake autoconf libtool pkg-config
```

### Lỗi: "windres not found"
```bash
# Cài đặt MinGW tools
sudo apt install -y mingw-w64-tools
```

## Build trên Windows (Native)

Nếu muốn build trực tiếp trên Windows:

1. **Cài đặt MSYS2:**
   - Download từ: https://www.msys2.org/
   - Cài đặt MinGW-w64 toolchain

2. **Cài đặt Go:**
   - Download từ: https://golang.org/dl/

3. **Chạy build script trong MSYS2 shell:**
```bash
# Mở MSYS2 MinGW 64-bit terminal
cd /c/path/to/buildWirepodXiaozhi/windows
./build.sh v1.0.0
```

## Kiểm Tra Build

Sau khi build xong, kiểm tra:

1. **File ZIP có tồn tại:**
```bash
ls -lh wire-pod-win-amd64.zip
```

2. **Giải nén và kiểm tra:**
```bash
unzip -l wire-pod-win-amd64.zip
```

3. **Test trên Windows:**
   - Copy ZIP sang máy Windows
   - Giải nén
   - Chạy `chipper.exe` để test

## Build Installer

Installer được build riêng với GUI:

```bash
./build-installer.sh v1.0.0
```

Installer sẽ:
- ✅ Download latest release từ GitHub (nếu cần)
- ✅ Hiển thị GUI để chọn thư mục cài đặt
- ✅ Cấu hình web port
- ✅ Tự động start WirePod sau khi cài
- ✅ Tạo registry entries
- ✅ Tạo shortcut

## Lưu Ý

1. **Version number:** Luôn cung cấp version khi chạy build script
2. **Dependencies:** Các thư viện native chỉ build một lần, lần sau sẽ skip
3. **Clean build:** Xóa thư mục `libs/` nếu muốn build lại từ đầu
4. **Commit hash:** Script tự động lấy commit hash từ wirepodxiaozhi repo

## Tùy Chỉnh Build

### Thay đổi build tags:
Sửa trong `build.sh`:
```bash
export GO_TAGS="nolibopusfile customtag"
```

### Thay đổi ldflags:
```bash
go build -ldflags "-H=windowsgui -w -s -X custom.var=value"
```

### Thay đổi output directory:
Sửa `PODLIBS` trong script:
```bash
export PODLIBS="${ORIGDIR}/custom-libs"
```

## Kết Luận

Sau khi hoàn thành, bạn sẽ có:
- ✅ `wire-pod-win-amd64.zip` - Package có thể phân phối
- ✅ `WirePodInstaller-v1.0.0.exe` - Installer GUI (nếu build)

Có thể phân phối các file này cho người dùng Windows để cài đặt và sử dụng WirePod.

