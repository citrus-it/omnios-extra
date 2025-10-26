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

PROG=patchutils
VER=0.4.4
PKG=ooce/text/patchutils
SUMMARY="$PROG"
DESC="A collection of tools that operate on patch files"

OPREFIX=$PREFIX
PREFIX+=/$PROG

set_arch 64
set_clangver

PATH=$GNUBIN:$PATH
XML_CATALOG_FILES=$OPREFIX/docbook-xsl/catalog.xml
export PATH XML_CATALOG_FILES

XFORM_ARGS="
    -DPREFIX=${PREFIX#/}
    -DOPREFIX=${OPREFIX#/}
    -DPROG=$PROG
    -DPKGROOT=$PROG
"

CONFIGURE_OPTS+="
    --with-patch=$GNUBIN/patch
    --with-diff=$GNUBIN/diff
"

init
download_source $PROG $PROG $VER
patch_source
prep_build autoconf -autoreconf
build
make_package
clean_up

# Vim hints
# vim:ts=4:sw=4:et:fdm=marker
