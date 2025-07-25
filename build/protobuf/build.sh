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

# Copyright 2025 OmniOS Community Edition (OmniOSce) Association.

. ../../lib/build.sh

PROG=protobuf
VER=29.3
PKG=ooce/developer/protobuf
SUMMARY="protobuf"
DESC="Google's language-neutral, platform-neutral, extensible mechanism "
DESC+="for serializing structured data"

forgo_isaexec

CONFIGURE_OPTS="
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=$PREFIX
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    -Dprotobuf_BUILD_TESTS=OFF
"

pre_configure() {
    typeset arch=$1

    CONFIGURE_OPTS[$arch]="
        -DCMAKE_INSTALL_LIBDIR=$PREFIX/${LIBDIRS[$arch]}
        -DZLIB_INCLUDE_DIR=${SYSROOT[$arch]}/usr/include
        -DZLIB_LIBRARY_RELEASE=${SYSROOT[$arch]}/usr/${LIBDIRS[$arch]}/libz.so
    "
}

CXXFLAGS[aarch64]+=" -mtls-dialect=trad"

init
clone_github_source -submodules $PROG "$GITHUB/protocolbuffers/$PROG" v$VER
append_builddir $PROG
prep_build cmake+ninja
patch_source
build -noctf    # C++
make_package
clean_up

# Vim hints
# vim:ts=4:sw=4:et:fdm=marker
