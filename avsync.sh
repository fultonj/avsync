#!/usr/bin/env bash
set -euo pipefail

### CONFIG ###
BASE="/Users/fultonj/Documents/reaper/Covers"
FPS=30
SR=48000

### DEFAULTS ###
T7="/Volumes/T7/Untitled"
KEEP_TMP=false
WIPE_T7=false

usage() {
  echo "Usage:"
  echo "  $0 --proj Slayer/Postmortem [--t7 /Volumes/T7/Untitled] [--audio Reaper.wav] [--keep-tmp] [--wipe-t7]"
  exit 1
}

### ARGS ###
while [[ $# -gt 0 ]]; do
  case "$1" in
    --t7) T7="$2"; shift 2 ;;
    --audio) AUDIO="$2"; shift 2 ;;
    --proj) PROJ_REL="$2"; shift 2 ;;
    --keep-tmp) KEEP_TMP=true; shift ;;
    --wipe-t7) WIPE_T7=true; shift ;;
    *) usage ;;
  esac
done

[[ -z "${PROJ_REL:-}" ]] && usage

PROJ="$BASE/$PROJ_REL"
VIDDIR="$PROJ/videos"
mkdir -p "$VIDDIR"

# If --audio wasn't provided, pick the only .wav in $PROJ, else list and exit
if [[ -z "${AUDIO:-}" ]]; then
  mapfile -t WAVS < <(ls "$PROJ"/*.wav 2>/dev/null || true)

  if [[ ${#WAVS[@]} -eq 0 ]]; then
    echo "Error: no .wav files found in $PROJ"
    exit 1
  elif [[ ${#WAVS[@]} -eq 1 ]]; then
    AUDIO="${WAVS[0]}"
    echo "Using audio: $AUDIO"
  else
    echo "Error: multiple .wav files found in $PROJ. Specify --audio explicitly:"
    for w in "${WAVS[@]}"; do
      echo "  $(basename "$w")"
    done
    exit 1
  fi
fi

# If user passed a relative audio path, resolve it relative to $PROJ
if [[ "$AUDIO" != /* ]]; then
  AUDIO="$PROJ/$AUDIO"
fi

# Basic sanity checks
[[ -d "$T7" ]] || { echo "Error: T7 path not found: $T7"; exit 1; }
[[ -f "$AUDIO" ]] || { echo "Error: audio file not found: $AUDIO"; exit 1; }

### FIND NEXT importN ###
N=1
while [[ -d "$VIDDIR/import$N" ]]; do
  ((N++))
done
OUT="$VIDDIR/import$N"
mkdir -p "$OUT"

TMP="$(mktemp -d)"
trap '[[ "$KEEP_TMP" == false ]] && rm -rf "$TMP"' EXIT

echo "T7 input: $T7"
echo "Project:  $PROJ"
echo "Audio:    $AUDIO"
echo "Temp dir: $TMP"
echo "Output:   $OUT"

### COPY INPUTS ###
cp -X "$T7/Video ISO Files/Untitled CAM 1 01.mp4" "$TMP/CAM1.mp4"
cp -X "$T7/Video ISO Files/Untitled CAM 2 01.mp4" "$TMP/CAM2.mp4"
cp -X "$T7/Video ISO Files/Untitled CAM 3 01.mp4" "$TMP/CAM3.mp4"
cp -X "$T7/Audio Source Files/Untitled MIC 1 01.wav" "$TMP/LTC.wav"
cp -X "$AUDIO" "$TMP/track.wav"

### COMPUTE OFFSET ###
# Parse the first LTC frame after #DISCONTINUITY and read its start sample (field 4)
FIRST_SAMPLE=$(
  ltcdump -f "$FPS" "$TMP/LTC.wav" 2>/dev/null |
  awk '
    /^#DISCONTINUITY/ { getline; print $4; exit }
  '
) || true

if [[ -z "${FIRST_SAMPLE:-}" ]]; then
  echo "Error: no LTC frames detected in $T7/Audio Source Files/Untitled MIC 1 01.wav"
  exit 1
fi

SECONDS=$(echo "scale=6; $FIRST_SAMPLE / $SR" | bc)
FRAMES=$(echo "($SECONDS * $FPS)+0.5" | bc | cut -d. -f1)

TC_SEC=$((FRAMES / FPS))
TC_FR=$((FRAMES % FPS))
OFFSET=$(printf "00:00:%02d:%02d" "$TC_SEC" "$TC_FR")

echo "Computed audio offset: $OFFSET (from sample $FIRST_SAMPLE @ ${SR}Hz, ${FPS}fps)"

### STAMP VIDEOS (start at 00:00:00:01) ###
for i in 1 2 3; do
  ffmpeg -loglevel error -y -i "$TMP/CAM$i.mp4" \
    -c copy -timecode 00:00:00:01 \
    "$OUT/CAM${i}_tc.mp4"
done

### STAMP AUDIO (wrapper MOV with OFFSET timecode) ###
DUR=$(ffprobe -v error -show_entries format=duration -of default=nk=1:nw=1 "$TMP/track.wav")

AUDIO_BASENAME="$(basename "$AUDIO")"
AUDIO_STEM="${AUDIO_BASENAME%.wav}"

ffmpeg -loglevel error -y -f lavfi -r "$FPS" \
  -t "$DUR" \
  -i "color=size=16x16:color=black" \
  -i "$TMP/track.wav" \
  -shortest -c:v prores -profile:v 3 -c:a copy \
  -timecode "$OFFSET" \
  "$OUT/${AUDIO_STEM}_tc.mov"

### VERIFY TIMECODES ###
echo "Verifying embedded timecodes:"
for f in "$OUT"/CAM*_tc.mp4 "$OUT/${AUDIO_STEM}_tc.mov"; do
  echo "$f"
  ffprobe -v error -select_streams v:0 -show_entries stream_tags=timecode -of default=nw=1 "$f"
done

### OPTIONAL WIPE ###
if [[ "$WIPE_T7" == true ]]; then
  echo "Removing T7 Untitled directory: $T7"
  rm -rf "$T7"
fi

echo "Done. Import into Resolve from:"
echo "  $OUT"
