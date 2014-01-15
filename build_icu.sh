#!/bin/sh

CORE_TOP=`pwd`
export CORE_TOP

CURLBIN=`which curl`
if ! test -n "CURLBIN"; then
    display_error "Error: curl is required. Add it to 'PATH'"
    exit 1
fi

GUNZIP=`which gunzip`
UNZIP=`which unzip`
TAR=`which tar`
GNUMAKE=`which gmake 2>/dev/null || which make`
PATCHES=$CORE_TOP/patches
STATICLIBS=$CORE_TOP/.libs
DISTDIR=$CORE_TOP/.dists

# icu sources
ICU_VER=4.4.2
ICU_DISTNAME=icu4c-4_4_2-src.tgz
ICU_SITE=http://dl.refuge.io
ICUDIR=$STATICLIBS/icu


[ "$MACHINE" ] || MACHINE=`(uname -m) 2>/dev/null` || MACHINE="unknown"
[ "$RELEASE" ] || RELEASE=`(uname -r) 2>/dev/null` || RELEASE="unknown"
[ "$SYSTEM" ] || SYSTEM=`(uname -s) 2>/dev/null`  || SYSTEM="unknown"
[ "$BUILD" ] || VERSION=`(uname -v) 2>/dev/null` || VERSION="unknown"


CFLAGS="-g -O2 -Wall"
LDFLAGS="-lstdc++"
ARCH=
ISA64=
GNUMAKE=make
CC=gcc
CXX=g++
PATCH=patch
case "$SYSTEM" in
    Linux)
        ARCH=`arch 2>/dev/null`
        ;;
    FreeBSD|OpenBSD|NetBSD)
        ARCH=`(uname -p) 2>/dev/null`
        GNUMAKE=gmake
        ;;
    Darwin)
        ARCH=`(uname -p) 2>/dev/null`
        ISA64=`(sysctl -n hw.optional.x86_64) 2>/dev/null`
        ;;
    Solaris)
        ARCH=`(uname -p) 2>/dev/null`
        GNUMAKE=gmake
        PATCH=gpatch
        ;;
    *)
        ARCH="unknown"
        ;;
esac


# TODO: add mirror & signature validation support
fetch()
{
    TARGET=$DISTDIR/$1
    if ! test -f $TARGET; then
        echo "==> Fetch $1 to $TARGET"
        $CURLBIN --progress-bar -L $2/$1 -o $TARGET
    fi
}

build_icu()
{
    fetch $ICU_DISTNAME $ICU_SITE

    mkdir -p $ICUDIR

    echo "==> icu (compile)"

    rm -rf $STATICLIBS/icu*

    cd $STATICLIBS
    $GUNZIP -c $DISTDIR/$ICU_DISTNAME | $TAR xf -

    # apply patches
    cd $STATICLIBS/icu
    for P in $PATCHES/icu/*.patch; do \
        (patch -p0 -i $P || echo "skipping patch"); \
    done

    cd $ICUDIR/source

    CFLAGS="-g -Wall -fPIC -Os"

    env CC="gcc" CXX="g++" CPPFLAGS="" LDFLAGS="-fPIC" \
	CFLAGS="$CFLAGS" CXXFLAGS="$CFLAGS" \
        ./configure --disable-debug \
		    --enable-static \
		    --disable-shared \
		    --disable-icuio \
		    --disable-layout \
		    --disable-extras \
		    --disable-tests \
		    --disable-samples \
		    --prefix=$STATICLIBS/icu && \
        $GNUMAKE && $GNUMAKE install
}

do_setup()
{
    echo "==> build icu"
    mkdir -p $DISTDIR
    mkdir -p $STATICLIBS
}

do_builddeps()
{
    if [ ! -f $STATICLIBS/icu/lib/libicui18n.a ]; then
        build_icu
    fi
}


clean()
{
    rm -rf $STATICLIBS
    rm -rf $DISTDIR
}



usage()
{
    cat << EOF
Usage: $basename [command] [OPTIONS]

The $basename command compile Mozilla Spidermonkey and ICU statically
for couch_core.

Commands:

    all:        build couch_core static libs
    clean:      clean static libs
    -?:         display usage

Report bugs at <https://github.com/refuge/couch_core>.
EOF
}


if [ ! "x$COUCHDB_STATIC" = "x1" ]; then
    exit 0
fi

if [ ! "x$USE_STATIC_ICU" = "x1" ]; then
    exit 0
fi

if [ "x$1" = "x" ]; then
    do_setup
    do_builddeps
	exit 0
fi

case "$1" in
    all)
        shift 1
        do_setup
        do_builddeps
        ;;
    clean)
        shift 1
        clean
        ;;
    help|--help|-h|-?)
        usage
        exit 0
        ;;
    *)
        echo $basename: ERROR Unknown command $arg 1>&2
        echo 1>&2
        usage 1>&2
        echo "### $basename: Exitting." 1>&2
        exit 1;
        ;;
esac


exit 0
