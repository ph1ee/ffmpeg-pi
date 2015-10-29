#!/bin/bash

tools="/opt/tools"
libaacplus="libaacplus-2.0.2"
faac="faac-1.28"
lame="lame-3.99"
x264="x264"
ffmpeg="ffmpeg"

destdir=$(mktemp -d)

CONF="--host=arm-linux --prefix=/usr --enable-static --disable-shared"

install_prerequisites() {
	sudo apt-get install build-essential git-core
}

setup_crosstools() {
	[[ -d "$tools" ]] || sudo git clone https://github.com/raspberrypi/tools.git "$tools"

	export CCPREFIX=arm-bcm2708hardfp-linux-gnueabi-

	export PATH="$PATH:$tools/arm-bcm2708/arm-bcm2708hardfp-linux-gnueabi/bin"

	export CC=arm-bcm2708hardfp-linux-gnueabi-gcc
	export CXX=arm-bcm2708hardfp-linux-gnueabi-g++

	export MAKEFLAGS="-j$(getconf _NPROCESSORS_ONLN)"
}

build_libaacplus() {
	[[ -d "$libaacplus" ]] || wget -qO- http://tipok.org.ua/downloads/media/aacplus/libaacplus/libaacplus-2.0.2.tar.gz | tar xz

	(cd "$libaacplus" &&
		./autogen.sh --with-parameter-expansion-string-replace-capable-shell=/bin/bash $CONF && DESTDIR="$destdir" make install)
}

build_faac() {
	[[ -d "$faac" ]] || wget -qO- - http://downloads.sourceforge.net/project/faac/faac-src/faac-1.28/faac-1.28.tar.gz | tar xz

	fixed=".fixed"
	[[ ! -f "$fixed" ]] && patch -p0 < fix-strcasestr.patch && touch "$fixed"

	(cd "$faac" && ./configure $CONF && DESTDIR="$destdir" make install)
}

build_lame() {
	[[ -d "$lame" ]] || wget -qO- - http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.tar.gz | tar xz

	(cd "$lame" && ./configure $CONF && DESTDIR="$destdir" make install)
}

build_x264() {
	[[ -d "$x264" ]] || git clone git://git.videolan.org/x264 "$x264"

	(cd x264 && ./configure $CONF --disable-asm && DESTDIR="$destdir" make install)
}

build_ffmpeg() {

	extra_cflags="-mcpu=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard"

	[[ -d "$ffmpeg" ]] || git clone git://source.ffmpeg.org/ffmpeg.git "$ffmpeg"

	(cd "$ffmpeg" && ./configure --arch=armel --cross-prefix=${CCPREFIX} --enable-cross-compile --target-os=linux --prefix=/usr \
		--disable-shared --enable-gpl --enable-version3 --enable-nonfree --disable-doc --enable-libmp3lame --enable-libfaac --enable-libx264 \
		--extra-cflags="-I$destdir/usr/include $extra_cflags" --extra-ldflags="-ldl -L$destdir/usr/lib" && make)
}

install_prerequisites
setup_crosstools
#build_libaacplus
build_faac
build_lame
build_x264
build_ffmpeg
