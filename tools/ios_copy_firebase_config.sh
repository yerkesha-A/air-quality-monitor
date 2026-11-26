#!/bin/sh
# Firebase is optional for a guest build. Never embed stale or mismatched config.
set -eu
source_plist="${PROJECT_DIR}/Runner/GoogleService-Info.plist"
bundle_dir="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
bundled_plist="${bundle_dir}/GoogleService-Info.plist"
if [ -f "$source_plist" ]; then
  actual_bundle=$(/usr/libexec/PlistBuddy -c 'Print :BUNDLE_ID' "$source_plist")
  if [ "$actual_bundle" != "$PRODUCT_BUNDLE_IDENTIFIER" ]; then
    echo 'error: Private Firebase plist does not match the Runner Bundle ID.' >&2
    exit 1
  fi
  mkdir -p "$bundle_dir"
  cp "$source_plist" "$bundled_plist"
elif [ -f "$bundled_plist" ]; then
  echo 'error: Stale Firebase configuration in build output. Use a separate derived data directory.' >&2
  exit 1
else
  echo 'Firebase configuration absent: building guest monitoring without cloud login.'
fi
