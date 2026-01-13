# Thông Tin Debug - Chipper.exe

## Các File Chipper.exe Tìm Khi Khởi Động

Khi `chipper.exe` chạy, nó sẽ tìm các file sau:

### 1. File Certificate (Bắt buộc)
- **`./epod/ep.crt`** - Certificate file
- **`./epod/ep.key`** - Private key file

**Vị trí:** Phải nằm trong thư mục `chipper/epod/`

### 2. File Cấu Hình (Tự động tạo nếu không có)
- **`./apiConfig.json`** - Cấu hình API (tự động tạo nếu không có)
- **`./version`** - File version (phải có sẵn)

### 3. Thư Mục Cần Thiết
- **`./intent-data/`** - Dữ liệu intent (nhiều ngôn ngữ)
- **`./webroot/`** - Web interface files
- **`./epod/`** - Chứa certificates

## Lỗi "The system cannot find the file specified"

### Nguyên nhân có thể:

1. **Thiếu file `epod/ep.crt` hoặc `epod/ep.key`**
   - Kiểm tra: `C:\wire-pod\chipper\epod\ep.crt` có tồn tại không?
   - Kiểm tra: `C:\wire-pod\chipper\epod\ep.key` có tồn tại không?

2. **Working directory không đúng**
   - Khi double-click, working directory có thể không phải là thư mục chứa `chipper.exe`
   - **Giải pháp:** Luôn chạy từ Command Prompt:
     ```cmd
     cd C:\wire-pod\chipper
     chipper.exe
     ```

3. **Thiếu DLL files**
   - Tất cả file `.dll` phải nằm cùng thư mục với `chipper.exe`

## Cách Kiểm Tra

### Bước 1: Kiểm tra file epod
```cmd
dir C:\wire-pod\chipper\epod
```
Phải thấy:
- `ep.crt`
- `ep.key`

### Bước 2: Kiểm tra working directory
Tạo file `test.bat` trong thư mục `chipper\`:
```batch
@echo off
cd /d "%~dp0"
echo Current directory: %CD%
echo.
echo Checking files...
if exist "epod\ep.crt" (
    echo [OK] epod\ep.crt exists
) else (
    echo [ERROR] epod\ep.crt NOT FOUND!
)
if exist "epod\ep.key" (
    echo [OK] epod\ep.key exists
) else (
    echo [ERROR] epod\ep.key NOT FOUND!
)
if exist "version" (
    echo [OK] version exists
) else (
    echo [ERROR] version NOT FOUND!
)
echo.
pause
chipper.exe
```

### Bước 3: Chạy từ Command Prompt để xem lỗi chi tiết
```cmd
cd C:\wire-pod\chipper
chipper.exe
```

## File Log

Nếu chương trình chạy được một chút rồi mới lỗi, kiểm tra log:
- `%APPDATA%\wire-pod\` - Thư mục config
- Xem file log trong đó để biết lỗi cụ thể

