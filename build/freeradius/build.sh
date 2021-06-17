#!/usr/bin/bash
#
# {{{ CDDL HEADER
#
# This file and its contents are supplied under the terms of the
# Common Development and Distribution License ("CDDL"), version 1.0.
# You may only use this file in accordance with the terms of version
# 1.0 of the CDDL.
#
# A full copy of the text of the CDDL should have accompanied this
# source. A copy of the CDDL is also available via the Internet at
# http://www.illumos.org/license/CDDL.
# }}}

# Copyright 2021 OmniOS Community Edition (OmniOSce) Association.

. ../../lib/functions.sh

PROG=freeradius
PKG=ooce/server/freeradius
TALLOCVER=2.3.2
VER=3.0.23
MAJVER=${VER%.*}            # M.m
sMAJVER=${MAJVER//./}       # Mm
SUMMARY="FreeRADIUS $MAJVER"
DESC="The open source implementation of RADIUS, an IETF protocol for AAA (Authorisation, Authentication, and Accounting)."

OPREFIX=$PREFIX
PREFIX+=/$PROG-$MAJVER

BUILD_DEPENDS_IPS="
    ooce/library/mariadb-${MARIASQLVER//./}
"

set_arch 64

## build talloc dependancy
# NOTE: talloc only builds as 64-bit
save_buildenv

set_mirror "https://www.samba.org/ftp"
set_checksum sha256 "27a03ef99e384d779124df755deb229cd1761f945eca6d200e8cfd9bf5297bd7"

CONFIGURE_OPTS="
    --prefix=$PREFIX
    --disable-python
"
build_dependency talloc talloc-$TALLOCVER talloc talloc $TALLOCVER

restore_buildenv

tallocinc=$DEPROOT$PREFIX/include
talloclib=$DEPROOT$PREFIX/lib/$ISAPART64

## build freeradius
set_builddir $PROG-server-$VER

#set_mirror "ftp://ftp.freeradius.org/pub"
set_mirror "http://ftp.ntua.gr/mirror"
set_checksum sha256 "08ce42bf0ec217704ca163619c06efcae8a6d6a8ae7a626d77da9a6fd210e235"


CONFIGURE_OPTS_64="
    --prefix=$PREFIX
    --sysconfdir=/etc$OPREFIX
    --with-logdir=/var/log/$PROG
    --localstatedir=/var/$OPREFIX/$PROG
    --with-raddbdir=/etc$OPREFIX/$PROG-$MAJVER
    --libdir=$PREFIX/lib/$ISAPART64
    --with-openssl-include-dir=$OPREFIX/include
    --with-openssl-lib-dir=$OPREFIX/lib/$ISAPART64
"
    #--with-talloc-include-dir=$PREFIX/include
    #--with-talloc-lib-dir=$PREFIX/lib/$ISAPART64
CFLAGS64+=" -D_XPG4_2"
CPPFLAGS64+=" -I$tallocinc"
LDFLAGS64+=" -L$OPREFIX/lib/$ISAPART6 -L$talloclib -R$OPREFIX/lib/$ISAPART64 -R$PREFIX/lib/$ISAPART64"
#LDFLAGS64+=" -L${OPREFIX}/mariadb-${MARIASQLVER}/lib/${ISAPART64} -R${OPREFIX}/mariadb-${MARIASQLVER}/lib/${ISAPART64}"

addpath PKG_CONFIG_PATH64 $talloclib/pkgconfig

XFORM_ARGS="
    -DPREFIX=${PREFIX#/}
    -DOPREFIX=${OPREFIX#/}
    -DPROG=$PROG
    -DVERSION=$MAJVER
    -DsVERSION=$sMAJVER
    -DDsVERSION=-$sMAJVER
    -DUSER=radius
    -DGROUP=radius
"

save_function make_install _make_install
make_install() {
    _make_install "$@"

    # Copy in the dependency libraries

    pushd $talloclib >/dev/null
    for lib in libtalloc*; do
        [[ $lib = *.so.* && -f $lib && ! -h $lib ]] || continue
        tgt=`echo $lib | cut -d. -f1-3`
        logmsg "--- installing library $lib -> $tgt"
        logcmd cp $lib $DESTDIR/$PREFIX/lib/$ISAPART64/$tgt \
            || logerr "cp $tgt"
    done
    popd >/dev/null

    pushd $DESTDIR/$PREFIX >/dev/null

    # Unfortunately, libtool insists on adding $DEPROOT to the runtime
    # library path in each binary and library. Fixing this up post-install
    # for now, there may be a better way to do it.
    typeset rpath="$PREFIX/lib/$ISAPART64:$OPREFIX/lib/$ISAPART64:${OPREFIX}/mariadb-${MARIASQLVER}/lib/${ISAPART64}"
    rpath+=":/usr/gcc/$GCCVER/lib/$ISAPART64"

    for f in bin/* sbin/* libexec/* lib/$ISAPART64/*; do
        [ -f $f -a ! -h $f ] || continue
        logmsg "--- fixing runpath in $f"
        logcmd elfedit -e "dyn:value -s RUNPATH $rpath" $f
        logcmd elfedit -e "dyn:value -s RPATH $rpath" $f
    done
}

init
download_source $PROG "$PROG-server" $VER
prep_build
xform files/freeradius-template.xml > $TMPDIR/$PROG-$sMAJVER.xml
xform files/freeradius-template.sh > $TMPDIR/$PROG-$sMAJVER
MAKE_INSTALL_ARGS="R=$DESTDIR"
build -ctf
install_smf ooce $PROG-$sMAJVER.xml $PROG-$sMAJVER
make_package
clean_up

# Vim hints
# vim:ts=4:sw=4:et:fdm=marker
