#!/bin/bash
set -e

# 
# Credit to Meghthedev 
# for the initial script.

export DEVICE="fogos"
export PROJECTFOLDER="Pixel15"
export PROJECTID="82"
export REPO_INIT="repo init -u https://github.com/PixelOS-AOSP/manifest.git -b fifteen --git-lfs --depth=1"
export BUILD_DIFFERENT_ROM="$REPO_INIT"

if (grep -q "$PROJECTFOLDER" <(crave clone list --json | jq -r '.clones[]."Cloned At"')) || [ "${DCDEVSPACE}" == "1" ]; then   
   crave clone destroy -y /crave-devspaces/$PROJECTFOLDER || echo "Error removing $PROJECTFOLDER"
else
   rm -rf $PROJECTFOLDER || true
fi

if [ "${DCDEVSPACE}" == "1" ]; then
   crave clone create --projectID $PROJECTID /crave-devspaces/$PROJECTFOLDER || echo "Crave clone create failed!"
   cd /crave-devspaces/$PROJECTFOLDER
else
   mkdir $PROJECTFOLDER
   cd $PROJECTFOLDER
   echo "Running $REPO_INIT"
   $REPO_INIT
fi

# RUN inside foss.crave.io devspace
# REMOVE existing local_manifests
crave run --no-patch -- "rm -rf .repo/local_manifests && \
$BUILD_DIFFERENT_ROM && \
git clone https://github.com/sm6375-PixelOS/local_manifests -b fifteen .repo/local_manifests \
/opt/crave/resync.sh && \ 
source build/envsetup.sh && \
lunch aosp_$DEVICE-bp1a-userdebug && \
mka bacon"

cd ..

if grep -q "$PROJECTFOLDER" <(crave clone list --json | jq -r '.clones[]."Cloned At"') || [ "${DCDEVSPACE}" == "1" ]; then
  crave clone destroy -y /crave-devspaces/$PROJECTFOLDER || echo "Error removing $PROJECTFOLDER"
else  
  rm -rf $PROJECTFOLDER || true
fi

/opt/crave/telegram/upload.sh
