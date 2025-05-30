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

# Copyright 2024 OmniOS Community Edition (OmniOSce) Association.

. ../../lib/build.sh

PROG=libid3tag
VER=0.15.1b
PKG=ooce/library/libid3tag
SUMMARY="libid3tag"
DESC="ID3 tag manipulation library."

set_clangver

CONFIGURE_OPTS="
    --disable-static
"

LDFLAGS[i386]+=" -lssp_ns"

pre_configure() {
    typeset arch=$1

    ! cross_arch $arch && return

    LDFLAGS[$arch]+=" -L${SYSROOT[$arch]}/usr/${LIBDIRS[$arch]}"
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
