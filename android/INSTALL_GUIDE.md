# Hướng dẫn cài đặt APK WirePod cho Android

## Vị trí file APK

Sau khi build thành công, file APK sẽ nằm tại:

```
/home/linh/demoxiaozhi/buildWirepodXiaozhi/android/WirePod-<VERSION>.apk
```

Ví dụ: `WirePod-1.0.0.apk`

## Cách cài đặt APK vào máy Android

Có 3 cách chính để cài đặt APK:

### Cách 1: Cài đặt qua ADB (Android Debug Bridge) - Khuyến nghị

**Yêu cầu:**
- Máy Android đã bật USB Debugging
- Đã cài đặt ADB trên máy tính

**Các bước:**

1. **Kết nối máy Android với máy tính qua USB**

2. **Bật USB Debugging trên Android:**
   - Vào Settings → About phone
   - Nhấn 7 lần vào "Build number" để bật Developer options
   - Vào Settings → Developer options
   - Bật "USB debugging"

3. **Kiểm tra kết nối:**
   ```bash
   cd /home/linh/demoxiaozhi/buildWirepodXiaozhi/android
   adb devices
   ```
   Nếu thấy thiết bị hiển thị, bạn đã kết nối thành công.

4. **Cài đặt APK:**
   ```bash
   adb install WirePod-1.0.0.apk
   ```
   
   Nếu muốn ghi đè lên phiên bản cũ:
   ```bash
   adb install -r WirePod-1.0.0.apk
   ```

### Cách 2: Copy APK trực tiếp vào máy Android

**Các bước:**

1. **Copy file APK vào máy Android:**
   - Kết nối máy Android với máy tính qua USB
   - Copy file `WirePod-1.0.0.apk` vào thư mục Download trên máy Android
   - Hoặc gửi file qua email/cloud storage và tải về trên máy Android

2. **Cài đặt trên máy Android:**
   - Mở File Manager trên máy Android
   - Tìm file `WirePod-1.0.0.apk` trong thư mục Download
   - Nhấn vào file APK
   - Nếu có cảnh báo về "Unknown sources", vào Settings → Security → Bật "Install unknown apps"
   - Nhấn "Install"

### Cách 3: Sử dụng ứng dụng quản lý file từ xa

**Các bước:**

1. **Sử dụng ứng dụng như AirDroid, Send Anywhere, hoặc Google Drive:**
   - Upload file APK lên cloud storage
   - Tải về trên máy Android
   - Cài đặt như Cách 2

## Lưu ý quan trọng

1. **Cho phép cài đặt từ nguồn không xác định:**
   - Android có thể chặn cài đặt APK từ nguồn không xác định
   - Vào Settings → Security → Bật "Unknown sources" hoặc "Install unknown apps"

2. **Kiểm tra phiên bản Android:**
   - APK này hỗ trợ Android API 16+ (Android 4.1+)
   - Đảm bảo máy Android của bạn đáp ứng yêu cầu

3. **Gỡ cài đặt phiên bản cũ (nếu có):**
   ```bash
   adb uninstall com.kercre123.wirepod
   ```

## Kiểm tra cài đặt thành công

Sau khi cài đặt, bạn có thể kiểm tra:

```bash
# Liệt kê các ứng dụng đã cài
adb shell pm list packages | grep wirepod

# Hoặc kiểm tra trên máy Android
# Vào Settings → Apps → Tìm "WirePod"
```

## Troubleshooting

### Lỗi "INSTALL_FAILED_UPDATE_INCOMPATIBLE"
- Gỡ cài đặt phiên bản cũ trước:
  ```bash
  adb uninstall com.kercre123.wirepod
  ```

### Lỗi "INSTALL_FAILED_INSUFFICIENT_STORAGE"
- Xóa bớt dữ liệu trên máy Android để có đủ dung lượng

### Lỗi "INSTALL_PARSE_FAILED_NO_CERTIFICATES"
- File APK chưa được ký đúng cách
- Chạy lại script build để tạo lại APK

### Không thấy thiết bị trong `adb devices`
- Kiểm tra USB cable
- Thử cổng USB khác
- Kiểm tra lại USB Debugging đã bật chưa
- Chấp nhận "Allow USB debugging" popup trên máy Android

## Thông tin thêm

- Package name: `com.kercre123.wirepod`
- App ID: `com.kercre123.wirepod`
- Minimum Android version: API 16 (Android 4.1)

