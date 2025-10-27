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

PROG=gh
PKG=ooce/util/gh
VER=2.82.1
SUMMARY="github-cli"
DESC="The GitHub CLI tool"

set_arch 64
set_gover

RUN_DEPENDS_IPS="developer/versioning/git"

# No configure
configure_amd64() { :; }

MAKE_INSTALL_ARGS="prefix=$PREFIX"

init
clone_go_source cli cli v$VER
patch_source
prep_build
build -noctf
make_package
clean_up

# Vim hints
# vim:ts=4:sw=4:et:fdm=marker
