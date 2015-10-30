# Cross Compiling FFmpeg for Raspberry Pi

Simply run `./build_ffmpeg.sh`, then copy `ffmpeg` to your Pi.

All FFmpeg executables link external libraries statically.

You're ready to broadcasting your Pi if you have RPi camera.
```sh
raspivid -o - \ # pipe to stdout
-t 0 \ # don't stop
-w 1280 -h 720 \ # 1280x720
-fps 30 \ # 30 fps
-b 1000000 \ # 1000 Kbps
-g 30 \ # I-frame interval
-pf main \ # main profile
| \
ffmpeg -v info \
-ar 44100 -ac 2 -acodec pcm_s16le -f s16le -ac 2 -i /dev/zero \
-f h264 -i - \
-vcodec copy -acodec aac -ab 128k -strict experimental \
-f flv "$RTMP_ENDPOINT"
```
