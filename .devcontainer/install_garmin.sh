#!/bin/bash

# exit immediately on command failure, treat unset variables as errors, 
#     and fail on pipeline errors
set -euo pipefail

# 1. Update and install GUI dependencies required for the SDK Manager
sudo apt-get update && sudo apt-get install -y \
    wget \
    unzip \
    openjdk-17-jre-headless \
    libwebkit2gtk-4.0-37 \
    libgtk-3-0 \
    libnss3 \
    libasound2 \
    libxtst6 \
    libxss1 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libgbm1 \
    libsm6 \
    libice6

# 2. Create the Garmin directory structure
mkdir -p ~/.Garmin/ConnectIQ/Sdks

# 3. Download the SDK Manager
# Note: You may need to update this URL if Garmin rotates their generic download links
echo "Downloading Garmin SDK Manager..."
SDK_MGR_URL="https://developer.garmin.com/downloads/connect-iq/sdk-manager/connectiq-sdk-manager-linux.zip"
wget "$SDK_MGR_URL" -O /tmp/sdkmanager.zip

# 4. Extract to a local bin folder or your preferred location
mkdir -p ~/sdkmanager
unzip /tmp/sdkmanager.zip -d ~/sdkmanager/

# Current SDK Manager zip places the binary under ~/sdkmanager/bin/sdkmanager.
chmod +x ~/sdkmanager/bin/sdkmanager

# Keep backwards compatibility with older docs/scripts that use ~/sdkmanager/sdkmanager.
ln -sf ~/sdkmanager/bin/sdkmanager ~/sdkmanager/sdkmanager

# 5. Post-install checks and next-step guidance
echo "Running post-install checks..."

if ! command -v java >/dev/null 2>&1; then
    echo "ERROR: Java runtime not found on PATH."
    echo "Install it with: sudo apt-get update && sudo apt-get install -y openjdk-17-jre-headless"
    exit 1
fi

echo "Java runtime check passed: $(java -version 2>&1 | head -n 1)"

if [[ ! -x ~/sdkmanager/bin/sdkmanager ]]; then
    echo "ERROR: ~/sdkmanager/bin/sdkmanager not found or not executable."
    echo "Re-run: bash .devcontainer/install_garmin.sh"
    exit 1
fi

MISSING_LIBS=""
if ! ldconfig -p | grep -q 'libSM.so.6'; then
    MISSING_LIBS="${MISSING_LIBS} libsm6"
fi
if ! ldconfig -p | grep -q 'libICE.so.6'; then
    MISSING_LIBS="${MISSING_LIBS} libice6"
fi

if [[ -n "$MISSING_LIBS" ]]; then
    echo "WARNING: Missing runtime libraries:${MISSING_LIBS}"
    echo "Install them with: sudo apt-get update && sudo apt-get install -y${MISSING_LIBS}"
else
    echo "Runtime library check passed (libSM.so.6 and libICE.so.6 found)."
fi

# Smoke test startup without launching the full GUI window.
if ~/sdkmanager/bin/sdkmanager --help >/tmp/garmin_sdkmanager_help.log 2>&1; then
    echo "SDK Manager smoke test passed."
else
    echo "WARNING: SDK Manager smoke test failed."
    echo "Last output:"
    tail -n 20 /tmp/garmin_sdkmanager_help.log || true
fi

echo "Installation complete."
echo "To launch: ~/sdkmanager/sdkmanager"
echo
echo "After devcontainer build says 'Done. Press any key to close the terminal':"
echo "1) Close that terminal."
echo "2) Open a new terminal in this devcontainer: Terminal -> New Terminal."
echo "3) Run: ~/sdkmanager/sdkmanager"
