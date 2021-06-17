#!/usr/bin/ksh

# This file and its contents are supplied under the terms of the
# Common Development and Distribution License ("CDDL"), version 1.0.
# You may only use this file in accordance with the terms of version
# 1.0 of the CDDL.
#
# A full copy of the text of the CDDL should have accompanied this
# source. A copy of the CDDL is also available via the Internet at
# http://www.illumos.org/license/CDDL.

source /lib/svc/share/smf_include.sh

if [ -z "$SMF_FMRI" ]; then
	echo "SMF framework variables are not initialised."
	exit $SMF_EXIT_ERR
fi

RADIUSD="`svcprop -c -p config/exec $SMF_FMRI`"
CONF_DIR="`svcprop -c -p config/dir $SMF_FMRI`"

[ -e "$RADIUSD" ] || exit $SMF_EXIT_ERR_CONFIG
[ -d "$CONF_DIR" ] || exit $SMF_EXIT_ERR_CONFIG

# freeradius config is a complex dir with files to update, remove,
# (or add) to avoid pkg upgrade from breaking a users config, we
# copy the example config here if radiusd.conf is missing
function copy_example_config {
	cp -a /$(PREFIX)/share/examples/raddb/. "${CONF_DIR}/"
}

case "$1" in
start)
	[ -e "${CONF_DIR}/radiusd.conf" ] || copy_example_config
	exec ${RADIUSD} -d "$CONF_DIR" 2>&1
	;;
*)
	echo "Unknown method."
	exit $SMF_EXIT_ERR_FATAL
	;;
esac

exit 0

