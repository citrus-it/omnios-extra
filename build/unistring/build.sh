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
# Copyright 2025 OmniOS Community Edition (OmniOSce) Association.

. ../../lib/build.sh

PROG=unistring
VER=1.3
PKG=ooce/library/unistring
SUMMARY="Unicode string manipulation library"
DESC="libunistring - $SUMMARY"

test_relver '>=' 151053 && set_clangver
set_standard XPG6
set_builddir lib$PROG-$VER

TESTSUITE_FILTER="^[A-Z#][A-Z ]"

XFORM_ARGS="-DPREFIX=${PREFIX#/}"

CONFIGURE_OPTS="--disable-namespacing"

CPPFLAGS+=" -DOOCEVER=$OOCEVER"

init
download_source $PROG lib$PROG $VER
patch_source
prep_build
build
run_testsuite check
make_package
clean_up

# Vim hints
# vim:ts=4:sw=4:et:fdm=marker
