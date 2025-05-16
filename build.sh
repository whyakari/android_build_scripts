#!/bin/bash
set -e

export DEVICE="fogos"
export PROJECTFOLDER="Pixel15"
export PROJECTID="82"
export REPO_INIT="repo init -u https://github.com/PixelOS-AOSP/manifest.git -b fifteen --git-lfs --depth=1"
export BUILD_DIFFERENT_ROM="$REPO_INIT"

# RUN inside foss.crave.io devspace
crave run --no-patch -- "
rm -rf .repo/local_manifests && \
$BUILD_DIFFERENT_ROM && \
git clone https://github.com/sm6375-PixelOS/local_manifests -b fifteen .repo/local_manifests && \
/opt/crave/resync.sh && \
# MotCamera4
mkdir -p vendor/motorola/fogos/proprietary/product/priv-app/MotCamera4/ && \
wget -O vendor/motorola/fogos/proprietary/product/priv-app/MotCamera4/MotCamera4.apk 'https://dumps.tadiphone.dev/dumps/motorola/fogos/-/raw/user-15-V1UG35H.75-14-a4cca-release-keys/product/priv-app/MotCamera4/MotCamera4.apk' && \
# BUILD
source build/envsetup.sh && \
lunch aosp_$DEVICE-bp1a-userdebug && \
mka bacon
"

OUT_DIR="/crave-devspaces/$PROJECTFOLDER/out/target/product/$DEVICE"

ROM_ZIP=$(find "$OUT_DIR" -type f -name "*.zip" | head -n 1)
BOOT_IMG="$OUT_DIR/boot.img"
DTBO_IMG="$OUT_DIR/dtbo.img"
VENDOR_BOOT_IMG="$OUT_DIR/vendor_boot.img"

wget https://raw.githubusercontent.com/GustavoMends/go-up/master/go-up
chmod +x go-up

./go-up "$ROM_ZIP"
./go-up "$BOOT_IMG"
./go-up "$DTBO_IMG"
if [ -f "$VENDOR_BOOT_IMG" ]; then
    ./go-up "$VENDOR_BOOT_IMG"
fi

if grep -q "$PROJECTFOLDER" <(crave clone list --json | jq -r '.clones[]."Cloned At"') || [ "${DCDEVSPACE}" == "1" ]; then
  crave clone destroy -y /crave-devspaces/$PROJECTFOLDER || echo "Error removing $PROJECTFOLDER"
else  
  rm -rf $PROJECTFOLDER || true
fi
