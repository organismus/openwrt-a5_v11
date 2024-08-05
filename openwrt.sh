#!/bin/bash

SCRIPT_DIR=`dirname -- "$0"`

if [ -z "$V" ] ; then
	echo "Environment variable V not defined. Example: V=21.0.5"
	exit 1
fi
V=${V#v} # Remove prefix 'v' (if passed)

echo "Building version $V"

if [ $# -eq 0 ] ; then
	echo "Action(s) required. Available actions: fetch configure patch make http"
	exit 1
fi

for arg in "$@"
do
  case $arg in
    fetch)
      echo "Fetching..."
      (cd $SCRIPT_DIR && git clone --depth 1 -b v$V git://git.openwrt.org/openwrt/openwrt.git) && \
      (cat $SCRIPT_DIR/feeds.conf.default >> $SCRIPT_DIR/openwrt/feeds.conf.default) && \
      (cd openwrt && ./scripts/feeds update -a && ./scripts/feeds install -a)
      if [ "${V%%.*}" -ge 22 ] ; then
        # From version 22.* can use LLVM
        # https://forum.openwrt.org/t/snapshots-fail-to-build-because-of-llvm-bpf/141017/6
        # wget -qO- https://downloads.openwrt.org/snapshots/targets/ramips/rt305x/llvm-bpf-15.0.6.Linux-x86_64.tar.xz | tar xJ
        # wget -qO- https://downloads.openwrt.org/snapshots/targets/ramips/rt305x/llvm-bpf-18.1.7.Linux-x86_64.tar.zst | tar x --zstd
        # wget -qO- https://archive.openwrt.org/releases/23.05.3/targets/ramips/rt305x/llvm-bpf-15.0.7.Linux-x86_64.tar.xz | tar xJ
        # wget -qO- https://archive.openwrt.org/releases/22.03.7/targets/ramips/rt305x/llvm-bpf-13.0.0.Linux-x86_64.tar.xz | tar xJ
	#LLVM=$(lynx -nonumbers --dump -listonly https://archive.openwrt.org/releases/$V/targets/ramips/rt305x/ | grep llvm)
        [ ! -z "$LLVM" ] && wget -qO- "$LLVM" | tar xJ
      fi
      ;;
    configure)
      if [ -f $SCRIPT_DIR/.config-v${V%%.*} ] ; then
	cp $SCRIPT_DIR/.config-v${V%%.*} $SCRIPT_DIR/openwrt/.config
      else
        wget -qO $SCRIPT_DIR/openwrt/.config https://downloads.openwrt.org/releases/$V/targets/ramips/rt305x/config.buildinfo
      fi
      (cd $SCRIPT_DIR/openwrt && make defconfig)
      ;;
    patch)
      echo "Patching..."
        (cd $SCRIPT_DIR/openwrt && \
	vermagic=`wget -qO- https://downloads.openwrt.org/releases/$V/targets/ramips/rt305x/openwrt-$V-ramips-rt305x.manifest |grep kernel | rev |cut -d- -f1 |rev` && \
        sed -Ei "s/(mkhash|\$(MKHASH)) md5/echo $vermagic/" include/kernel-defaults.mk && \
	patch -p1 <../a5-v11_v${V%%.*}.patch)
      ;;
    make)
      echo "Building..."
      (cd $SCRIPT_DIR/openwrt && time make -j$(($(nproc) + 2)) download world)
      ;;
    http)
      echo "Starting http server..."
      exec mini_httpd -p 8080 -D -dd $SCRIPT_DIR/openwrt
      ;;
    *)
      echo "Wrong action: $arg"
      exit 2
      ;;
  esac
done

