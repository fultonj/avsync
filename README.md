# avsync

Audio Video Synchronization: How I import aligned video recorded with
LTC data from Reaper

[avsync.sh](avsync.sh) automates the process described in [manual.md](manual.md)

```
[fultonj@jove avsync{main}]$ ./avsync.sh --proj Slayer/Postmortem
Using audio: /Users/fultonj/Documents/reaper/Covers/Slayer/Postmortem/PostmortemGuitar.wav
T7 input: /Volumes/T7/Untitled
Project:  /Users/fultonj/Documents/reaper/Covers/Slayer/Postmortem
Audio:    /Users/fultonj/Documents/reaper/Covers/Slayer/Postmortem/PostmortemGuitar.wav
Temp dir: /var/folders/6c/__w_y21n61d_n8l5qjhm50b80000gn/T/tmp.jzIam3mY1H
Output:   /Users/fultonj/Documents/reaper/Covers/Slayer/Postmortem/videos/import1
Computed audio offset: 00:00:02:05 (from sample 103268 @ 48000Hz, 30fps)
Verifying embedded timecodes:
/Users/fultonj/Documents/reaper/Covers/Slayer/Postmortem/videos/import1/CAM1_tc.mp4
TAG:timecode=00:00:00:01
/Users/fultonj/Documents/reaper/Covers/Slayer/Postmortem/videos/import1/CAM2_tc.mp4
TAG:timecode=00:00:00:01
/Users/fultonj/Documents/reaper/Covers/Slayer/Postmortem/videos/import1/CAM3_tc.mp4
TAG:timecode=00:00:00:01
/Users/fultonj/Documents/reaper/Covers/Slayer/Postmortem/videos/import1/PostmortemGuitar_tc.mov
TAG:timecode=00:00:02:05
Done. Import into Resolve from:
  /Users/fultonj/Documents/reaper/Covers/Slayer/Postmortem/videos/import1
[fultonj@jove avsync{main}]$
```
