#!/usr/bin/env bash
set -euo pipefail

T7="/Volumes/T7/Untitled"

usage() {
  cat <<'EOF'
Usage:
  clean.sh <SUF> [--dry-run] [--force]

Examples:
  ./clean.sh 01 --dry-run
  ./clean.sh 01
  ./clean.sh 01 --force

Notes:
  - SUF can be "01" or "1"; it will be normalized to two digits ("01").
  - Default base directory: /Volumes/T7/Untitled
EOF
}

DRY_RUN=0
FORCE=0

if [[ $# -lt 1 ]]; then
  usage
  exit 2
fi

SUF_RAW="$1"
shift || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run|-n) DRY_RUN=1 ;;
    --force|-f)   FORCE=1 ;;
    --help|-h)    usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
  shift
done

# Normalize suffix: "1" -> "01", "01" stays "01"
if [[ "$SUF_RAW" =~ ^[0-9]{1,2}$ ]]; then
  SUF="$(printf '%02d' "$SUF_RAW")"
else
  echo "SUF must be a number like 01 (or 1)." >&2
  exit 2
fi

# Safety checks
if [[ ! -d "$T7" ]]; then
  echo "Base directory not found: $T7" >&2
  exit 1
fi
if [[ "$T7" != /Volumes/*/Untitled ]]; then
  echo "Refusing to run: T7 path looks unexpected: $T7" >&2
  exit 1
fi

PROGRAM_FILE="$T7/Untitled ${SUF}.mp4"

FILES=(
  "$PROGRAM_FILE"
  "$T7/Video ISO Files/Untitled CAM 1 ${SUF}.mp4"
  "$T7/Video ISO Files/Untitled CAM 2 ${SUF}.mp4"
  "$T7/Video ISO Files/Untitled CAM 3 ${SUF}.mp4"
  "$T7/Video ISO Files/Untitled CAM 4 ${SUF}.mp4"
  "$T7/Audio Source Files/Untitled MIC 1 ${SUF}.wav"
  "$T7/Audio Source Files/Untitled MIC 2 ${SUF}.wav"
)

echo "Base: $T7"
echo "Suffix: $SUF"
echo
echo "Targets:"
for f in "${FILES[@]}"; do
  if [[ -e "$f" ]]; then
    echo "  EXISTS  $f"
  else
    echo "  MISSING $f"
  fi
done

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo
  echo "Dry-run: no files deleted."
  exit 0
fi

echo
if [[ "$FORCE" -eq 0 ]]; then
  read -r -p "Delete the EXISTING files listed above? Type 'yes' to proceed: " ans
  if [[ "$ans" != "yes" ]]; then
    echo "Aborted."
    exit 1
  fi
fi

for f in "${FILES[@]}"; do
  if [[ -e "$f" ]]; then
    rm -f -- "$f"
    echo "DELETED $f"
  else
    echo "SKIP    $f"
  fi
done
