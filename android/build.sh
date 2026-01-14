#!/bin/bash

set -e

# Use wirepodxiaozhi-main or wirepodxiaozhi repo
if [ -d "../../wirepodxiaozhi-main" ]; then
    WP_COMMIT_HASH=$(cd ../../wirepodxiaozhi-main && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
elif [ -d "../../wirepodxiaozhi" ]; then
    WP_COMMIT_HASH=$(cd ../../wirepodxiaozhi && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
else
    WP_COMMIT_HASH="github"
fi
GOLDFLAGS="-X 'github.com/kercre123/wire-pod/chipper/pkg/vars.CommitSHA=${WP_COMMIT_HASH}'"


# Detect actual user home directory even when running with sudo
if [[ -n "$SUDO_USER" ]]; then
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
elif [[ -n "$USER" ]]; then
    REAL_HOME=$(getent passwd "$USER" | cut -d: -f6)
else
    REAL_HOME=$HOME
fi

if [[ ${GHACTIONS} == "" ]]; then
    # Check ANDROID_HOME environment variable first
    if [[ -n "$ANDROID_HOME" && -d "$ANDROID_HOME" ]]; then
        export ANDROID_HOME="$ANDROID_HOME"
    else
        export ANDROID_HOME=$REAL_HOME/Android/Sdk
    fi
    
    # Try to find NDK - check for newer structure first (ndk/version), then old (ndk-bundle)
    NDK_PATH=""
    if [[ -d "${ANDROID_HOME}/ndk-bundle" ]]; then
        NDK_PATH="${ANDROID_HOME}/ndk-bundle"
    elif [[ -d "${ANDROID_HOME}/ndk" ]]; then
        # Find the latest NDK version
        LATEST_NDK=$(ls -1d "${ANDROID_HOME}/ndk"/* 2>/dev/null | sort -V | tail -1)
        if [[ -n "$LATEST_NDK" && -d "$LATEST_NDK" ]]; then
            NDK_PATH="$LATEST_NDK"
        fi
    fi
    
    if [[ -n "$NDK_PATH" ]]; then
        export TCHAIN=${NDK_PATH}/toolchains/llvm/prebuilt/linux-x86_64/bin
        export ANDROID_NDK_HOME="$NDK_PATH"
    else
        export TCHAIN=${ANDROID_HOME}/ndk-bundle/toolchains/llvm/prebuilt/linux-x86_64/bin
        export ANDROID_NDK_HOME="${ANDROID_HOME}/ndk-bundle"
    fi
    
    export APKSIGNER=${ANDROID_HOME}/build-tools/34.0.0/apksigner
elif [[ ${GHACTIONS} == "true" ]]; then
    export ANDROID_HOME="$(pwd)/android-ndk"
    export TCHAIN=${ANDROID_HOME}/ndk-bundle/toolchains/llvm/prebuilt/linux-x86_64/bin
    export APKSIGNER="$(pwd)/android-14/apksigner"
fi

if [[ ! $1 ]]; then
	echo "You must provide a verison (./build.sh 1.0.0)"
	exit 1
fi
ORIGVERSION=$1
VERSION=${1#v}
if [[ $1 == "main" ]]; then
    ORIGVERSION=v1.0.0
    VERSION=1.0.0
fi
if [[ ! -d $TCHAIN ]]; then
    echo "Error: Couldn't find Android NDK toolchain at: $TCHAIN"
    echo ""
    echo "Android SDK/NDK is required for building Android apps."
    echo ""
    
    # Check if install script exists
    INSTALL_SCRIPT="$(dirname "$0")/install-android-sdk.sh"
    if [[ -f "$INSTALL_SCRIPT" ]]; then
        echo "Quick installation option:"
        echo "  Run: $INSTALL_SCRIPT"
        echo ""
        echo "Or manually install using one of these methods:"
    else
        echo "Installation options:"
    fi
    
    echo "1. Install Android Studio and SDK through Android Studio"
    echo "   - Download from: https://developer.android.com/studio"
    echo "   - Install Android SDK and NDK through SDK Manager"
    echo ""
    echo "2. Install command-line tools only:"
    echo "   mkdir -p $REAL_HOME/Android/Sdk"
    echo "   cd $REAL_HOME/Android/Sdk"
    echo "   wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip"
    echo "   unzip commandlinetools-linux-9477386_latest.zip"
    echo "   mkdir -p cmdline-tools/latest"
    echo "   mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true"
    echo "   ./cmdline-tools/latest/bin/sdkmanager --sdk_root=\$PWD \"platform-tools\" \"platforms;android-34\" \"build-tools;34.0.0\" \"ndk;25.2.9519653\""
    echo ""
    echo "3. Or set ANDROID_HOME environment variable:"
    echo "   export ANDROID_HOME=/path/to/your/android/sdk"
    echo ""
    echo "Current ANDROID_HOME: $ANDROID_HOME"
    echo "Expected NDK path: ${ANDROID_HOME}/ndk-bundle or ${ANDROID_HOME}/ndk/<version>"
    exit 1
fi
# Find Go binary path - use user's Go even when running with sudo
# Priority: Go 1.23.x > Go 1.22.x > Go 1.20
GO_BIN=""
GO_VERSION=""

# Try to find Go 1.23.x first (required by go.mod)
for go_dir in "$REAL_HOME/.gvm/gos"/go1.23*; do
    if [[ -d "$go_dir" && -f "$go_dir/bin/go" ]]; then
        GO_BIN="$go_dir/bin/go"
        GO_VERSION=$($GO_BIN version 2>/dev/null | head -1)
        break
    fi
done

# If Go 1.23 not found, try Go 1.22.x
if [[ -z "$GO_BIN" ]]; then
    for go_dir in "$REAL_HOME/.gvm/gos"/go1.22*; do
        if [[ -d "$go_dir" && -f "$go_dir/bin/go" ]]; then
            GO_BIN="$go_dir/bin/go"
            GO_VERSION=$($GO_BIN version 2>/dev/null | head -1)
            break
        fi
    done
fi

# If still not found, check PATH
if [[ -z "$GO_BIN" ]] && command -v go &> /dev/null; then
    GO_BIN=$(which go)
    GO_VERSION=$($GO_BIN version 2>/dev/null | head -1)
    # Check if it's Go 1.23 or higher
    if [[ ! "$GO_VERSION" =~ go1\.(2[3-9]|[3-9][0-9]) ]]; then
        # Not Go 1.23+, try to find Go 1.23 in GVM
        if [[ -f "$REAL_HOME/.gvm/gos/go1.23.12/bin/go" ]]; then
            GO_BIN="$REAL_HOME/.gvm/gos/go1.23.12/bin/go"
            GO_VERSION=$($GO_BIN version 2>/dev/null | head -1)
        fi
    fi
fi

# Last resort: try Go 1.20
if [[ -z "$GO_BIN" && -f "$REAL_HOME/.gvm/gos/go1.20/bin/go" ]]; then
    GO_BIN="$REAL_HOME/.gvm/gos/go1.20/bin/go"
    GO_VERSION=$($GO_BIN version 2>/dev/null | head -1)
    echo "Warning: Using Go 1.20, but go.mod requires Go 1.23. This may cause issues."
fi

if [[ -z "$GO_BIN" || ! -f "$GO_BIN" ]]; then
    echo "Error: Could not find Go installation"
    echo "Please install Go 1.23 or higher (go.mod requires Go 1.23)"
    exit 1
fi

echo "Using Go: $GO_BIN"
echo "Go version: $GO_VERSION"

# Get GOPATH from user's Go
export PATH="$(dirname "$GO_BIN"):$PATH"
USER_GOPATH=$($GO_BIN env GOPATH 2>/dev/null)
if [[ -z "$USER_GOPATH" ]]; then
    # Fallback to common GVM paths
    if [[ "$GO_BIN" == *"go1.23"* ]]; then
        USER_GOPATH="$REAL_HOME/.gvm/pkgsets/go1.23.12/global"
    elif [[ "$GO_BIN" == *"go1.22"* ]]; then
        USER_GOPATH="$REAL_HOME/.gvm/pkgsets/go1.22.6/global"
    else
        USER_GOPATH="$REAL_HOME/.gvm/pkgsets/go1.20/global"
    fi
fi

# Find fyne tool - check multiple possible locations
# Priority: fyne in current Go's GOPATH > system fyne > other Go versions
FYNE_PATH=""
if [[ -n "$USER_GOPATH" && -f "$USER_GOPATH/bin/fyne" ]]; then
    FYNE_PATH="$USER_GOPATH/bin/fyne"
elif command -v fyne &> /dev/null; then
    FYNE_PATH=$(which fyne)
    # Check if it's from the same Go version
    FYNE_GO_BIN=$(dirname "$(dirname "$FYNE_PATH")")/gos/*/bin/go 2>/dev/null || true
    if [[ -n "$FYNE_GO_BIN" && "$FYNE_GO_BIN" != *"$(basename $(dirname $GO_BIN))"* ]]; then
        # fyne is from different Go version, prefer installing new one
        FYNE_PATH=""
    fi
elif [[ -f "$REAL_HOME/go/bin/fyne" ]]; then
    FYNE_PATH="$REAL_HOME/go/bin/fyne"
fi

if [[ -z "$FYNE_PATH" || ! -f "$FYNE_PATH" ]]; then
    echo "Couldn't find fyne tool, installing it with Go $GO_VERSION..."
    echo "Using Go: $GO_BIN"
    echo "GOPATH: $USER_GOPATH"
    
    # Install fyne using current Go version
    $GO_BIN install fyne.io/fyne/v2/cmd/fyne@latest
    
    # Try to find it again after installation
    if [[ -n "$USER_GOPATH" && -f "$USER_GOPATH/bin/fyne" ]]; then
        FYNE_PATH="$USER_GOPATH/bin/fyne"
    elif command -v fyne &> /dev/null; then
        FYNE_PATH=$(which fyne)
    else
        echo "Error: Failed to install or locate fyne tool"
        exit 1
    fi
fi

if [[ ! -f "$FYNE_PATH" ]]; then
    echo "Error: fyne tool not found at $FYNE_PATH"
    exit 1
fi

echo "Using fyne: $FYNE_PATH"
export FYNE_PATH
if [[ ! -f key/ks.jks ]]; then
    echo "Signing keystore not found"
    echo "Generate a key with keytool. There must be a keystore at ./key/ks.jks and a password for that at ./key/passwd"
    echo 'Ex: "keytool -genkey -v -keystore your-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias your-alias"'
    exit 1
fi
if [[ ! -f key/passwd ]]; then
    echo "Signing keystore not found"
    echo "Generate a key with keytool. There must be a keystore at ./key/ks.jks and a password for that at ./key/passwd"
    echo 'Ex: "keytool -genkey -v -keystore your-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias your-alias"'
    exit 1
fi
echo "Zipping static files and bundling..."
cd resources
rm -rf webroot intent-data epod pod-bot-install.sh weather-map.json
# Use wirepodxiaozhi-main or wirepodxiaozhi repo
# From resources directory, need to go up 3 levels to reach demoxiaozhi root
if [ -d "../../../wirepodxiaozhi-main" ]; then
    cp -r ../../../wirepodxiaozhi-main/chipper/webroot .
    cp -r ../../../wirepodxiaozhi-main/chipper/intent-data .
    cp -r ../../../wirepodxiaozhi-main/chipper/epod .
    cp -r ../../../wirepodxiaozhi-main/vector-cloud/pod-bot-install.sh .
    cp -r ../../../wirepodxiaozhi-main/chipper/weather-map.json .
    cp -r ../../../wirepodxiaozhi-main/chipper/stttest.pcm .
elif [ -d "../../../wirepodxiaozhi" ]; then
    cp -r ../../../wirepodxiaozhi/chipper/webroot .
    cp -r ../../../wirepodxiaozhi/chipper/intent-data .
    cp -r ../../../wirepodxiaozhi/chipper/epod .
    cp -r ../../../wirepodxiaozhi/vector-cloud/pod-bot-install.sh .
    cp -r ../../../wirepodxiaozhi/chipper/weather-map.json .
    cp -r ../../../wirepodxiaozhi/chipper/stttest.pcm .
else
    echo "Error: wirepodxiaozhi-main or wirepodxiaozhi directory not found!"
    echo "Searched for:"
    echo "  - ../../../wirepodxiaozhi-main"
    echo "  - ../../../wirepodxiaozhi"
    exit 1
fi
echo $ORIGVERSION > version
zip -r static.zip .
cd ..
rm -f static.go
$FYNE_PATH bundle -o static.go resources/static.zip

# Use absolute paths for compilers to avoid issues when changing directories
BUILD_DIR=$(pwd)
ARM64_CC="${TCHAIN}/aarch64-linux-android23-clang"
ARM64_CXX="${TCHAIN}/aarch64-linux-android23-clang++"

# Find available armv7a compiler version (NDK 25+ doesn't have version 16)
ARM7_CC=""
ARM7_CXX=""
for version in 19 21 22 23 24; do
    if [[ -f "${TCHAIN}/armv7a-linux-androideabi${version}-clang" ]]; then
        ARM7_CC="${TCHAIN}/armv7a-linux-androideabi${version}-clang"
        ARM7_CXX="${TCHAIN}/armv7a-linux-androideabi${version}-clang++"
        break
    fi
done

if [[ -z "$ARM7_CC" || ! -f "$ARM7_CC" ]]; then
    echo "Error: Could not find armv7a-linux-androideabi compiler in $TCHAIN"
    echo "Available compilers:"
    ls -1 "${TCHAIN}"/armv7a-linux-androideabi*-clang 2>/dev/null | head -5 || echo "None found"
    exit 1
fi

echo "Using ARM64 compiler: $ARM64_CC"
echo "Using ARM7 compiler: $ARM7_CC"

export CC="$ARM64_CC"
export CXX="$ARM64_CXX"
export CGO_ENABLED=1
export CGO_LDFLAGS="-L${BUILD_DIR}/built-libs/arm64/lib"
export CGO_CFLAGS="-I${BUILD_DIR}/built-libs/arm64/include"
echo "Building vessel APK..."
cd vessel
GOOS=android GOARCH=arm64 $FYNE_PATH package -os android/arm64 -appID com.kercre123.wirepod -icon ../icons/png/podfull.png --name WirePod --tags nolibopusfile --appVersion $VERSION
cp WirePod.apk ../
cd ..
echo "Building WirePod for android/arm64..."
GOOS=android GOARCH=arm64 go build -buildmode=c-shared -ldflags="-s -w ${GOLDFLAGS}" -o libWirePod-arm64.so -tags nolibopusfile

export CC="$ARM7_CC"
export CXX="$ARM7_CXX"
export CGO_ENABLED=1
export CGO_LDFLAGS="-L${BUILD_DIR}/built-libs/armv7/lib"
export CGO_CFLAGS="-I${BUILD_DIR}/built-libs/armv7/include"
echo "Building WirePod for android/arm (GOARM=7)..."
GOOS=android GOARCH=arm GOARM=7 go build -buildmode=c-shared -ldflags="-s -w ${GOLDFLAGS}" -o libWirePod-armv7.so -tags nolibopusfile
echo "Putting libraries in vessel APK..."
rm -rf tmp
mkdir -p tmp
cd tmp
cp ../WirePod.apk .
mkdir -p lib/arm64-v8a
mkdir -p lib/armeabi-v7a
cp ../built-libs/arm64/lib/libopus.so lib/arm64-v8a/
cp ../built-libs/arm64/lib/libvosk.so lib/arm64-v8a/
cp ../built-libs/armv7/lib/libopus.so lib/armeabi-v7a/
cp ../built-libs/armv7/lib/libvosk.so lib/armeabi-v7a/
cp ../libWirePod-armv7.so lib/armeabi-v7a/libWirePod.so
cp ../libWirePod-arm64.so lib/arm64-v8a/libWirePod.so
zip -r WirePod.apk lib
${APKSIGNER} sign --ks ../key/ks.jks --ks-pass pass:"$(cat ../key/passwd)" --out ../WirePod.apk WirePod.apk
cd ..
rm -rf tmp
rm -f libWirePod-armv7.so
rm -f libWirePod-arm64.so
rm -f WirePod.apk.idsig
rm -f vessel/WirePod.apk
rm -f resources/static.zip
rm -f static.go
mv WirePod.apk WirePod-$VERSION.apk
echo "Build complete ./WirePod-$VERSION.apk"
