# Hướng Dẫn Cài Đặt WirePod cho Windows

## ⚠️ LỖI THƯỜNG GẶP

Nếu bạn gặp lỗi: **"The system cannot find the file specified"** khi chạy `chipper.exe`, vui lòng làm theo hướng dẫn dưới đây.

## 📦 Cách Giải Nén Đúng

### Bước 1: Giải nén file ZIP

1. **Tải file:** `wire-pod-win-amd64.zip`
2. **Giải nén vào thư mục:** `C:\wire-pod\` (hoặc bất kỳ thư mục nào bạn muốn)

**⚠️ QUAN TRỌNG:** Đảm bảo cấu trúc thư mục sau khi giải nén như sau:

```
C:\wire-pod\
├── chipper\
│   ├── chipper.exe          ← File chính
│   ├── libogg-0.dll
│   ├── libopus-0.dll
│   ├── libvosk.dll
│   ├── libstdc++-6.dll
│   ├── libgcc_s_seh-1.dll
│   ├── libwinpthread-1.dll
│   ├── version
│   ├── intent-data\
│   ├── webroot\
│   ├── epod\
│   └── icons\
├── vector-cloud\
│   └── build\
│       └── vic-cloud
└── uninstall.exe
```

### Bước 2: Chạy chương trình

**⚠️ QUAN TRỌNG:** KHÔNG double-click trực tiếp vào `chipper.exe`! 

**CÁCH 1: Sử dụng file batch script (Khuyến nghị)**
- Vào thư mục `C:\wire-pod\chipper\`
- Double-click vào `start-chipper.bat`
- File này sẽ tự động đảm bảo chạy từ đúng thư mục

**CÁCH 2: Command Prompt**
```cmd
cd C:\wire-pod\chipper
chipper.exe
```

**CÁCH 3: Tạo shortcut**
1. Right-click vào `start-chipper.bat`
2. Chọn "Create shortcut"
3. Di chuyển shortcut ra Desktop hoặc Start Menu
4. Double-click vào shortcut để chạy

## 🔍 Kiểm Tra

### 1. Kiểm tra cấu trúc thư mục

Đảm bảo bạn có đầy đủ các file sau trong thư mục `chipper\`:

- ✅ `chipper.exe` (khoảng 29-30 MB)
- ✅ `libogg-0.dll`
- ✅ `libopus-0.dll`
- ✅ `libvosk.dll`
- ✅ `libstdc++-6.dll`
- ✅ `libgcc_s_seh-1.dll`
- ✅ `libwinpthread-1.dll`
- ✅ `version` (file text nhỏ)
- ✅ Thư mục `intent-data\`
- ✅ Thư mục `webroot\`
- ✅ Thư mục `epod\`

### 2. Kiểm tra file version

Mở file `chipper\version` bằng Notepad, nó phải chứa version number (ví dụ: `v1.0.0`)

## ❌ Các Lỗi Thường Gặp

### Lỗi 1: "The system cannot find the file specified"

**Nguyên nhân:**
- **Chạy từ sai thư mục** - Khi double-click `chipper.exe`, working directory không đúng
- Giải nén sai cấu trúc thư mục
- Thiếu file `epod/ep.crt` hoặc `epod/ep.key`
- Thiếu DLL files

**Giải pháp:**
1. **Sử dụng `start-chipper.bat` thay vì double-click `chipper.exe`**
2. Hoặc chạy từ Command Prompt:
   ```cmd
   cd C:\wire-pod\chipper
   chipper.exe
   ```
3. Kiểm tra file epod:
   ```cmd
   dir C:\wire-pod\chipper\epod
   ```
   Phải thấy: `ep.crt` và `ep.key`
4. Nếu vẫn lỗi, giải nén lại file ZIP

### Lỗi 2: "Missing DLL"

**Nguyên nhân:** Thiếu DLL files

**Giải pháp:**
- Đảm bảo tất cả file `.dll` nằm trong cùng thư mục với `chipper.exe`
- Nếu thiếu, giải nén lại file ZIP

### Lỗi 3: Chương trình không chạy

**Nguyên nhân:** Windows Defender hoặc Antivirus chặn

**Giải pháp:**
1. Tắt Windows Defender tạm thời
2. Thêm thư mục vào whitelist của Antivirus
3. Chạy lại `chipper.exe`

## 🚀 Sau Khi Chạy Thành Công

1. Mở trình duyệt web
2. Truy cập: `http://localhost:8080`
3. Làm theo hướng dẫn trên web interface để cấu hình

## 📝 Lưu Ý

- **Không di chuyển** các file `.dll` ra khỏi thư mục `chipper\`
- **Không đổi tên** thư mục `chipper\` hoặc `vector-cloud\`
- **Luôn chạy** `chipper.exe` từ thư mục `chipper\`

## 🆘 Vẫn Gặp Lỗi?

Nếu vẫn gặp lỗi sau khi làm theo hướng dẫn:

1. **Kiểm tra log file:**
   - Vào `%APPDATA%\wire-pod\`
   - Xem file log để biết lỗi cụ thể

2. **Chạy từ Command Prompt:**
   ```cmd
   cd C:\wire-pod\chipper
   chipper.exe
   ```
   - Xem thông báo lỗi chi tiết

3. **Kiểm tra Windows Event Viewer:**
   - Mở Event Viewer
   - Xem Application Logs để tìm lỗi

