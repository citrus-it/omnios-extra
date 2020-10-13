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

# Copyright 2020 OmniOS Community Edition (OmniOSce) Association.

. ../../lib/functions.sh

PROG=unit
PKG=ooce/server/unit
VER=1.20.0
SUMMARY="nginx unit dynamic application server"
DESC="NGINX Unit is a dynamic application server which runs apps built with "
DESC+="multiple languages and frameworks."

set_arch 64
set_gover 1.15
PHPVER=7.4

MAJVER=${VER%.*}            # M.m
sMAJVER=${MAJVER//./}       # Mm

OPREFIX=$PREFIX
PREFIX+=/$PROG

# xxx
CFLAGS=${CFLAGS/-fno-aggressive-loop-optimizations/}

XFORM_ARGS="
    -DPREFIX=${PREFIX#/}
    -DOPREFIX=${OPREFIX#/}
    -DPROG=$PROG
    -DVERSION=$MAJVER
    -DsVERSION=$sMAJVER
"

CONFIGURE_OPTS_64=
CONFIGURE_OPTS="
    --prefix=$PREFIX
    --state=/var/run/$PROG
    --control=unix:/var/run/$PROG/control.unit.sock
    --pid=/var/run/$PROG/unix.pid
    --log=/var/run/$PROG/unit.log
    --tmp=/var/run/$PROG/tmp
    --openssl
    --cc=$CC
"
CONFIGURE_OPTS_WS="
    --ld-opt=\"-lxnet\"
    --cc-opt=\"$CFLAGS $CFLAGS64 -D_XPG4_2\"
"

save_function configure64 _configure64
configure64() {
    _configure64 "$@"
    logmsg "-- configuring perl"
    logcmd ./configure perl --perl=$PERL || logerr perl
    logmsg "-- configuring PHP $PHPVER"
    logcmd ./configure php --module=php${PHPVER//./} \
        --config=$OPREFIX/php-$PHPVER/bin/php-config \
        --lib-path=$OPREFIX/php-$PHPVER/lib \
        || logerr php
    logmsg "-- configuring Python $PYTHON2VER"
    logcmd ./configure python --module=py2 \
        --config=$USRBIN/python$PYTHON2VER-config || logerr py2
    logmsg "-- configuring Python $PYTHON3VER"
    logcmd ./configure python --module=py3 \
        --config=$USRBIN/python$PYTHON3VER-config || logerr py3
    logmsg "-- configuring Go $GOVER"
    logcmd ./configure go --go=$GO_PATH/bin/go --go-path=$GO_PATH || logerr go
    # php nodejs java ruby
}

init
download_source nginx $PROG $VER
patch_source
prep_build
build -ctf
#xform files/http-$PROG-template.xml > $TMPDIR/http-$PROG.xml
#xform files/http-$PROG-template > $TMPDIR/http-$PROG
#install_smf network http-$PROG.xml http-$PROG
make_package
clean_up

# Vim hints
# vim:ts=4:sw=4:et:fdm=marker
