#!/usr/bin/env bash
set -euo pipefail

### CONFIG ###
BASE="/Users/fultonj/Documents/reaper/Covers"
FPS=30
SR=48000
SUF=01

### DEFAULTS ###
T7="/Volumes/T7/Untitled"
KEEP_TMP=false

usage() {
  echo "Usage:"
  echo "  $0 --proj Slayer/Postmortem [--t7 /Volumes/T7/Untitled] [--audio Reaper.wav] [--suffix 01] [--keep-tmp]"
  exit 1
}

### ARGS ###
while [[ $# -gt 0 ]]; do
  case "$1" in
    --t7) T7="$2"; shift 2 ;;
    --audio) AUDIO="$2"; shift 2 ;;
    --proj) PROJ_REL="$2"; shift 2 ;;
    --suffix)
      [[ $# -ge 2 ]] || { echo "Error: --suffix requires a value"; exit 1; }
      SUF="$2"
      shift 2
      ;;
    --keep-tmp) KEEP_TMP=true; shift ;;
    *) usage ;;
  esac
done

[[ -z "${PROJ_REL:-}" ]] && usage
# Normalize/validate suffix (allow 1-2 digits; pad to 2)
[[ "$SUF" =~ ^[0-9]{1,2}$ ]] || { echo "Error: --suffix must be 1 or 2 digits (e.g. 1, 01, 10)"; exit 1; }
SUF=$(printf "%02d" "$SUF")

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
cp -X "$T7/Video ISO Files/Untitled CAM 1 ${SUF}.mp4" "$TMP/CAM1.mp4"
cp -X "$T7/Video ISO Files/Untitled CAM 2 ${SUF}.mp4" "$TMP/CAM2.mp4"
cp -X "$T7/Video ISO Files/Untitled CAM 3 ${SUF}.mp4" "$TMP/CAM3.mp4"

CAM4_SRC="$T7/Video ISO Files/Untitled CAM 4 ${SUF}.mp4"
if [[ -f "$CAM4_SRC" ]]; then
  cp -X "$CAM4_SRC" "$TMP/CAM4.mp4"
  HAS_CAM4=true
else
  HAS_CAM4=false
fi

cp -X "$T7/Audio Source Files/Untitled MIC 1 ${SUF}.wav" "$TMP/LTC.wav"
cp -X "$AUDIO" "$TMP/track.wav"

### COMPUTE OFFSET ###
decode_first_sample() {
  local wav="$1"
  ltcdump -f "$FPS" "$wav" 2>/dev/null |
    awk '
      /^#DISCONTINUITY/ { getline; print $4; exit }
    '
}

FIRST_SAMPLE=""

# Try RIGHT channel first (ATEM puts LTC on right)
ffmpeg -loglevel error -y -i "$TMP/LTC.wav" \
  -af "pan=mono|c0=c1" -ar "$SR" -c:a pcm_s16le \
  "$TMP/LTC_R.wav" || true

if [[ -f "$TMP/LTC_R.wav" ]]; then
  FIRST_SAMPLE="$(decode_first_sample "$TMP/LTC_R.wav" || true)"
fi

# Fallback: LEFT channel
if [[ -z "${FIRST_SAMPLE:-}" ]]; then
  ffmpeg -loglevel error -y -i "$TMP/LTC.wav" \
    -af "pan=mono|c0=c0" -ar "$SR" -c:a pcm_s16le \
    "$TMP/LTC_L.wav" || true

  if [[ -f "$TMP/LTC_L.wav" ]]; then
    FIRST_SAMPLE="$(decode_first_sample "$TMP/LTC_L.wav" || true)"
  fi
fi

# Last resort: original stereo
if [[ -z "${FIRST_SAMPLE:-}" ]]; then
  FIRST_SAMPLE="$(decode_first_sample "$TMP/LTC.wav" || true)"
fi

if [[ -z "${FIRST_SAMPLE:-}" ]]; then
  echo "Error: no LTC frames detected in $T7/Audio Source Files/Untitled MIC 1 ${SUF}.wav"
  exit 1
fi

FRAMES=$(
  awk -v s="$FIRST_SAMPLE" -v sr="$SR" -v fps="$FPS" \
    'BEGIN { printf "%d\n", (s/sr)*fps + 0.5 }'
)

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

if [[ "$HAS_CAM4" == true ]]; then
  ffmpeg -loglevel error -y -i "$TMP/CAM4.mp4" \
    -c copy -timecode 00:00:00:01 \
    "$OUT/CAM4_tc.mp4"
fi

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
  [[ -e "$f" ]] || continue
  echo "$f"
  ffprobe -v error -select_streams v:0 -show_entries stream_tags=timecode -of default=nw=1 "$f"
done

### Copy MIC 2 audio to use for manual sync as a backup
cp -X "$T7/Audio Source Files/Untitled MIC 2 ${SUF}.wav" "$OUT/${AUDIO_STEM}_mic2_backup.wav"

echo "Done. Import into Resolve from:"
echo "  $OUT"
