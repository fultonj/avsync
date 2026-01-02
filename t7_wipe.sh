#!/usr/bin/env bash
set -euo pipefail

T7="/Volumes/T7"
UMOUNT=0

# Ensure the volume is mounted
if [[ ! -d "$T7" ]]; then
  echo "Not mounted: $T7"
  exit 1
fi

cd "$T7"

# Delete only top-level directories whose names start with "Untitled"
shopt -s nullglob
targets=(Untitled*/)

if ((${#targets[@]} == 0)); then
  echo "No Untitled* directories found"
else
  echo "Will delete:"
  printf '  %q\n' "${targets[@]}"
  rm -rf -- "${targets[@]}"
  echo "Done deleting"
fi

if [[ $UMOUNT -lt 1 ]]; then
  exit 0
fi

# Unmount (handle QuickLook/Finder dissenters, then force if needed)
if ! diskutil unmount "$T7"; then
  echo "Unmount failed; attempting to release QuickLook/Finder locks..."
  qlmanage -r cache >/dev/null 2>&1 || true
  killall QuickLookUIService >/dev/null 2>&1 || true
  killall Finder >/dev/null 2>&1 || true

  echo "Retrying unmount (force)..."
  diskutil unmount force "$T7"
fi
