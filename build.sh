#!/bin/bash

set -e
#Credit to Meghthedev for the initial script 

export PROJECTFOLDER="Pixel15"
export PROJECTID="82"
export REPO_INIT="repo init -u https://github.com/PixelOS-AOSP/manifest.git -b fifteen --git-lfs --depth=1"
export BUILD_DIFFERENT_ROM="$REPO_INIT"

# Destroy Old Clones
if (grep -q "$PROJECTFOLDER" <(crave clone list --json | jq -r '.clones[]."Cloned At"')) || [ "${DCDEVSPACE}" == "1" ]; then   
   crave clone destroy -y /crave-devspaces/$PROJECTFOLDER || echo "Error removing $PROJECTFOLDER"
else
   rm -rf $PROJECTFOLDER || true
fi

# Create New clone
if [ "${DCDEVSPACE}" == "1" ]; then
   crave clone create --projectID $PROJECTID /crave-devspaces/$PROJECTFOLDER || echo "Crave clone create failed!"
   cd /crave-devspaces/$PROJECTFOLDER
else
   mkdir $PROJECTFOLDER
   cd $PROJECTFOLDER
   echo "Running $REPO_INIT"
   $REPO_INIT
fi

# Run inside foss.crave.io devspace
# Remove existing local_manifests
crave run --no-patch -- "rm -rf .repo/local_manifests && \

# Init Manifest
$BUILD_DIFFERENT_ROM && \

# Clone local_manifests repository
git clone https://github.com/sm6375-PixelOS/local_manifests -b fifteen .repo/local_manifests \

 # Sync the repositories
 /opt/crave/resync.sh && \ 

# Set up build environment
source build/envsetup.sh && \

# Lunch configuration
lunch aosp_bangkk-bp1a-userdebug && \

# Build the ROM
mka bacon"

cd ..

# Clean up
if grep -q "$PROJECTFOLDER" <(crave clone list --json | jq -r '.clones[]."Cloned At"') || [ "${DCDEVSPACE}" == "1" ]; then
  crave clone destroy -y /crave-devspaces/$PROJECTFOLDER || echo "Error removing $PROJECTFOLDER"
else  
  rm -rf $PROJECTFOLDER || true
fi
# Upload zips to Telegram
/opt/crave/telegram/upload.sh
