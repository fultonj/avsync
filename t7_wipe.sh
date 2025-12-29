#!/usr/bin/env bash
set -euo pipefail

T7="/Volumes/T7"
pushd $T7
for D in $(ls -F | grep / | grep -v app); do
    rm -rf $D
done
popd
diskutil unmount $T7
