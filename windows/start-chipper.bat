@echo off
REM Script để chạy chipper.exe từ đúng thư mục
REM Đảm bảo working directory là thư mục chứa chipper.exe

REM Lấy đường dẫn của file batch này
set "SCRIPT_DIR=%~dp0"

REM Chuyển đến thư mục chứa chipper.exe
cd /d "%SCRIPT_DIR%"

REM Kiểm tra file epod
if not exist "epod\ep.crt" (
    echo [ERROR] Khong tim thay file: epod\ep.crt
    echo [ERROR] Vui long kiem tra cau truc thu muc!
    pause
    exit /b 1
)

if not exist "epod\ep.key" (
    echo [ERROR] Khong tim thay file: epod\ep.key
    echo [ERROR] Vui long kiem tra cau truc thu muc!
    pause
    exit /b 1
)

REM Kiểm tra xem có file debug version không
if exist "chipper-debug.exe" (
    echo.
    echo ========================================
    echo Phat hien chipper-debug.exe
    echo Dang chay version debug (co console)...
    echo ========================================
    echo.
    echo Working directory: %CD%
    echo.
    echo ========================================
    echo CHI TIET LOG (se hien thi trong console):
    echo ========================================
    echo.
    chipper-debug.exe
    set EXIT_CODE=%ERRORLEVEL%
) else (
    echo.
    echo ========================================
    echo Chay chipper.exe (khong co console)
    echo ========================================
    echo.
    echo Working directory: %CD%
    echo.
    echo NOTE: chipper.exe khong hien thi log trong console.
    echo Neu gap loi, vui long:
    echo 1. Build version debug: ./build-debug.sh
    echo 2. Hoac kiem tra log trong: %APPDATA%\wire-pod
    echo.
    
    REM Chạy chipper.exe
    start /wait chipper.exe
    
    REM Kiểm tra exit code
    set EXIT_CODE=%ERRORLEVEL%
    
    REM Đợi một chút
    timeout /t 1 /nobreak >nul
)

REM Kiểm tra log file trong AppData
set "APPDATA_LOG=%APPDATA%\wire-pod"
if exist "%APPDATA_LOG%" (
    echo.
    echo ========================================
    echo TIM THAY LOG TRONG APPDATA:
    echo ========================================
    dir /b "%APPDATA_LOG%" 2>nul
    echo.
    if exist "%APPDATA_LOG%\dump.txt" (
        echo.
        echo ========================================
        echo PHAT HIEN DUMP FILE (co loi crash):
        echo ========================================
        type "%APPDATA_LOG%\dump.txt"
        echo.
    )
)

if %EXIT_CODE% NEQ 0 (
    echo.
    echo ========================================
    echo [ERROR] Chipper.exe da thoat voi loi!
    echo Exit code: %EXIT_CODE%
    echo ========================================
    echo.
    echo Vui long kiem tra:
    echo 1. Thu muc %APPDATA_LOG%
    echo 2. File dump.txt neu co
    echo 3. Build version debug de xem log chi tiet
    echo.
) else (
    echo.
    echo [OK] Chipper.exe da chay thanh cong!
    echo.
    echo Chuong trinh dang chay trong background.
    echo Kiem tra system tray de xem icon.
    echo.
)

pause

