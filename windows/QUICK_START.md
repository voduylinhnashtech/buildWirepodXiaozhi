# Hướng Dẫn Nhanh - Build WirePod cho Windows

## ⚠️ LỖI HIỆN TẠI

Bạn đang gặp lỗi: `autoreconf: not found`

**Nguyên nhân:** Thiếu các công cụ autotools cần thiết để build thư viện OGG và Opus.

## ✅ GIẢI PHÁP

### Bước 1: Cài đặt Dependencies

Chạy lệnh sau để cài đặt tất cả dependencies cần thiết:

```bash
sudo apt update && sudo apt install -y \
    mingw-w64 \
    mingw-w64-tools \
    build-essential \
    autotools-dev \
    automake \
    autoconf \
    libtool \
    pkg-config
```

**Hoặc sử dụng script tự động:**
```bash
cd /home/linh/demoxiaozhi/buildWirepodXiaozhi/windows
./install-deps.sh
```

### Bước 2: Kiểm tra Dependencies

Sau khi cài đặt, kiểm tra lại:

```bash
./check-deps.sh
```

Bạn sẽ thấy tất cả đều ✅ OK.

### Bước 3: Build

```bash
./build.sh v1.0.0
```

## 📋 Danh Sách Dependencies Cần Thiết

### Bắt buộc:
- ✅ **Go** (>= 1.18) - Đã có
- ❌ **mingw-w64** - Cross-compiler cho Windows
- ❌ **mingw-w64-tools** - windres để build resource files
- ❌ **autotools-dev** - Autotools development files
- ❌ **automake** - Tạo Makefile
- ❌ **autoconf** - Tạo configure scripts
- ❌ **libtool** - Quản lý shared libraries
- ✅ **pkg-config** - Đã có
- ✅ **git, wget, zip, unzip, make** - Đã có

## 🔍 Kiểm Tra Nhanh

Chạy các lệnh sau để kiểm tra:

```bash
# Kiểm tra Go
go version

# Kiểm tra MinGW
x86_64-w64-mingw32-gcc --version

# Kiểm tra Autotools
autoreconf --version
autoconf --version
automake --version
```

Nếu bất kỳ lệnh nào báo "command not found", bạn cần cài đặt package tương ứng.

## 🚀 Sau Khi Cài Đặt Xong

Build process sẽ:
1. ✅ Clone và build OGG library
2. ✅ Clone và build Opus library  
3. ✅ Download Vosk API
4. ✅ Cross-compile Go code cho Windows
5. ✅ Đóng gói thành `wire-pod-win-amd64.zip`

## 💡 Lưu Ý

- Build lần đầu sẽ mất thời gian vì cần build các thư viện native
- Các lần build sau sẽ nhanh hơn vì đã có sẵn libraries
- Nếu gặp lỗi, chạy `./check-deps.sh` để kiểm tra dependencies

