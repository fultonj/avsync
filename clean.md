# Cleaning Script

When I plug the T7 in after shooting video I might have multiple audio
and video for several takes. 

The [clean.sh](clean.sh) helps me delete all the videos connected to
one takes.

I browse the `Untitled` directory with the finder and know which files
I want to delete right away, e.g. if `Untitled 01.mp4` is only 5 MB, I 
know all of its associated files can go and then I use `clean.sh` like
this:

```
[fultonj@jove avsync{main}]$ ./clean.sh 01
Base: /Volumes/T7/Untitled
Suffix: 01

Targets:
  EXISTS  /Volumes/T7/Untitled/Untitled 01.mp4
  EXISTS  /Volumes/T7/Untitled/Video ISO Files/Untitled CAM 1 01.mp4
  EXISTS  /Volumes/T7/Untitled/Video ISO Files/Untitled CAM 2 01.mp4
  EXISTS  /Volumes/T7/Untitled/Video ISO Files/Untitled CAM 3 01.mp4
  EXISTS  /Volumes/T7/Untitled/Video ISO Files/Untitled CAM 4 01.mp4
  EXISTS  /Volumes/T7/Untitled/Audio Source Files/Untitled MIC 1 01.wav
  EXISTS  /Volumes/T7/Untitled/Audio Source Files/Untitled MIC 2 01.wav

Delete the EXISTING files listed above? Type 'yes' to proceed: yes
DELETED /Volumes/T7/Untitled/Untitled 01.mp4
DELETED /Volumes/T7/Untitled/Video ISO Files/Untitled CAM 1 01.mp4
DELETED /Volumes/T7/Untitled/Video ISO Files/Untitled CAM 2 01.mp4
DELETED /Volumes/T7/Untitled/Video ISO Files/Untitled CAM 3 01.mp4
DELETED /Volumes/T7/Untitled/Video ISO Files/Untitled CAM 4 01.mp4
DELETED /Volumes/T7/Untitled/Audio Source Files/Untitled MIC 1 01.wav
DELETED /Volumes/T7/Untitled/Audio Source Files/Untitled MIC 2 01.wav
[fultonj@jove avsync{main}]$
```
