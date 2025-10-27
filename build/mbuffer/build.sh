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
#
# Copyright 2011-2013 OmniTI Computer Consulting, Inc.  All rights reserved.
# Copyright 2025 OmniOS Community Edition (OmniOSce) Association.

. ../../lib/build.sh

PROG=mbuffer
VER=20250809
PKG=ooce/system/mbuffer
SUMMARY="$PROG - measuring buffer"
DESC="$PROG is a tool for buffering data streams"

OPREFIX=$PREFIX
PREFIX+="/$PROG"

set_arch 64
set_clangver

XFORM_ARGS="
    -DOPREFIX=${OPREFIX#/}
    -DPREFIX=${PREFIX#/}
    -DPROG=$PROG
    -DPKGROOT=$PROG
"

pre_configure() {
    typeset arch=$1

    ! cross_arch $arch && return

    LDFLAGS[$arch]+=" -L${SYSROOT[$arch]}/${LIBDIRS[$arch]}"
    export OBJDUMP="$CROSSTOOLS/$arch/bin/${TRIPLETS[$arch]}-objdump"
}

init
download_source $PROG $PROG $VER
patch_source
prep_build
build
make_package
clean_up

# Vim hints
# vim:ts=4:sw=4:et:fdm=marker
