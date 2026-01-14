#!/bin/bash

set -e

echo "=========================================="
echo "Android SDK & NDK Installation Script"
echo "=========================================="
echo ""

# Detect user home directory
if [[ -n "$SUDO_USER" ]]; then
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
elif [[ -n "$USER" ]]; then
    REAL_HOME=$(getent passwd "$USER" | cut -d: -f6)
else
    REAL_HOME=$HOME
fi

ANDROID_SDK_DIR="$REAL_HOME/Android/Sdk"

echo "Installing Android SDK to: $ANDROID_SDK_DIR"
echo ""

# Create directory
mkdir -p "$ANDROID_SDK_DIR"
cd "$ANDROID_SDK_DIR"

# Check if command-line tools already exist
if [[ ! -d "cmdline-tools" ]]; then
    echo "Downloading Android command-line tools..."
    if ! wget -q --show-progress https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip; then
        echo "Error: Failed to download command-line tools"
        exit 1
    fi
    
    echo "Extracting command-line tools..."
    unzip -q commandlinetools-linux-9477386_latest.zip
    rm commandlinetools-linux-9477386_latest.zip
    
    # Organize cmdline-tools structure
    if [[ ! -d "cmdline-tools/latest" ]]; then
        mkdir -p cmdline-tools/latest
        if [[ -d "cmdline-tools/bin" ]]; then
            mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true
        fi
    fi
else
    echo "Command-line tools already exist, skipping download..."
fi

# Set up environment
export ANDROID_HOME="$ANDROID_SDK_DIR"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

# Accept licenses
echo ""
echo "Accepting Android SDK licenses..."
yes | sdkmanager --sdk_root="$ANDROID_SDK_DIR" --licenses > /dev/null 2>&1 || {
    echo "Note: Some licenses may need manual acceptance"
}

# Install required components
echo ""
echo "Installing Android SDK components..."
echo "This may take several minutes..."

sdkmanager --sdk_root="$ANDROID_SDK_DIR" \
    "platform-tools" \
    "platforms;android-34" \
    "build-tools;34.0.0" \
    "ndk;25.2.9519653"

# Create symlink for ndk-bundle (for compatibility with old scripts)
if [[ -d "$ANDROID_SDK_DIR/ndk/25.2.9519653" ]] && [[ ! -d "$ANDROID_SDK_DIR/ndk-bundle" ]]; then
    echo ""
    echo "Creating ndk-bundle symlink for compatibility..."
    cd "$ANDROID_SDK_DIR/ndk"
    ln -s 25.2.9519653 ../ndk-bundle
fi

echo ""
echo "=========================================="
echo "Installation complete!"
echo "=========================================="
echo ""
echo "Android SDK location: $ANDROID_SDK_DIR"
echo ""
echo "To use this SDK, add to your ~/.bashrc or ~/.zshrc:"
echo "  export ANDROID_HOME=$ANDROID_SDK_DIR"
echo "  export PATH=\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$PATH"
echo ""
echo "Or run the build script with:"
echo "  export ANDROID_HOME=$ANDROID_SDK_DIR"
echo "  cd /home/linh/demoxiaozhi/buildWirepodXiaozhi/android"
echo "  ./build.sh 1.0.0"
echo ""

