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

# Copyright 2026 OmniOS Community Edition.  All rights reserved.

. ../../lib/build.sh

PROG=zabbix
VER=7.4.16
LIBEVENTVER=2.1.12
PKG=ooce/application/zabbix
SUMMARY="enterprise-class open source distributed monitoring solution"
DESC="Zabbix is software that monitors numerous parameters of a network "
DESC+="and the health and integrity of servers"

OPREFIX=$PREFIX
PREFIX+="/$PROG"

set_arch 64

BUILD_DEPENDS_IPS+="
    ooce/library/postgresql-${PGSQLVER//./}
    ooce/library/mariadb-${MARIASQLVER//./}
"

XFORM_ARGS="
    -DOPREFIX=${OPREFIX#/}
    -DPREFIX=${PREFIX#/}
    -DPROG=$PROG
    -DPKGROOT=$PROG
    -DVER=$VER
    -DUSER=zabbix -DGROUP=zabbix -DAGENTUSER=zabbixa
"

SKIP_RTIME_CHECK=1

pgconfig=$OPREFIX/pgsql-$PGSQLVER/bin/pg_config
mariaconfig=$OPREFIX/mariadb-$MARIASQLVER/bin/mariadb_config

CONFIGURE_OPTS="
    --sysconfdir=/etc/$PREFIX
    --datadir=$OPREFIX/share
    --enable-server
    --enable-ipv6
    --with-net-snmp
    --with-libcurl
    --with-libxml2
    --with-openssl
    --with-ldap=$OPREFIX
    "

CONFIGURE_OPTS[amd64]+="
    --libdir=$PREFIX/lib/
"

LDFLAGS+=" -R$OPREFIX/${LIBDIRS[amd64]}"
LIBS+=" -lumem"

init
prep_build

#########################################################################
# Zabbix requires libevent 2, which is part of the base system from
# r151059. Build a static copy for older releases.

if test_relver '<' 151059; then
    save_buildenv

    reset_configure_opts
    CONFIGURE_OPTS="
        --disable-shared
        --disable-openssl
        --disable-samples
        ac_cv_lib_xnet_socket=no
    "

    build_dependency libevent libevent-$LIBEVENTVER-stable \
        libevent libevent $LIBEVENTVER-stable

    restore_buildenv

    LEPREFIX=$DEPROOT$PREFIX
else
    LEPREFIX=/usr
fi

CONFIGURE_OPTS+=" --with-libevent=$LEPREFIX"
CONFIGURE_OPTS[amd64]+=" --with-libevent-lib=$LEPREFIX/${LIBDIRS[amd64]}"

#########################################################################

post_install() {
    logcmd rsync -a ui/ $DESTDIR/$PREFIX/ui/ \
        || logerr "rsync ui failed"

    logcmd mkdir -p $DESTDIR/$PREFIX/sql/
    logcmd rsync -a database/postgresql/*.sql $DESTDIR/$PREFIX/sql/pgsql/ \
        || logerr "rsync database failed"
    logcmd rsync -a database/mysql/*.sql $DESTDIR/$PREFIX/sql/mysql/ \
        || logerr "rsync database failed"

    logcmd rsync -a $SRCDIR/files/agentconf/ \
        $DESTDIR/etc/$PREFIX/zabbix_agentd.conf.d/ \
        || logerr "rsync agentconf failed"
    logcmd rsync -a $SRCDIR/files/scripts/ $DESTDIR/$PREFIX/scripts/ \
        || logerr "rsync scripts failed"
}

download_source $PROG $PROG $VER
patch_source
run_autoreconf -fi

#########################################################################
# Zabbix only supports being built with support for a single database
# type at a time. It's built twice, once for each database, then the
# final zabbix_server binary is mediated.

note -n "Building Postgres variant"

save_buildenv
CONFIGURE_OPTS+="
    --with-postgresql=$pgconfig
    --enable-agent
    --enable-proxy
"
LDFLAGS+=" -R`$pgconfig --libdir`"
build -ctf
restore_buildenv
unset -f post_install

note -n "Building Mariadb variant"

save_buildenv
save_variable DESTDIR
DESTDIR+="_mariadb"
CONFIGURE_OPTS+=" --with-mysql=$mariaconfig"
LDFLAGS+=" -R`$mariaconfig --libs | cut -d\  -f1 | cut -dL -f2`"
build -ctf
restore_variable DESTDIR
restore_buildenv

note -n "Packaging"

build_manifests() {
    manifest_start $TMPDIR/mf.agent
    manifest_add $PREFIX/bin zabbix_get zabbix_sender
    manifest_add $PREFIX/sbin zabbix_agentd
    manifest_add $PREFIX/share/man/man1 zabbix_get.1 zabbix_sender.1
    manifest_add $PREFIX/share/man/man8 zabbix_agentd.8
    manifest_add_dir $PREFIX/scripts
    manifest_add_dir $PREFIX/alertscripts
    manifest_add_dir $PREFIX/externalscripts
    manifest_add etc$PREFIX 'zabbix_agentd.*'
    manifest_add lib/svc/manifest/application zabbix-agent.xml
    manifest_finalise $TMPDIR/mf.agent $OPREFIX etc$OPREFIX

    manifest_uniq $TMPDIR/mf.{server,agent}
    manifest_finalise $TMPDIR/mf.server $OPREFIX etc$OPREFIX
}

# Move the zabbix server binaries, ready for mediation
logcmd mv $DESTDIR/$PREFIX/sbin/zabbix_server{,.pgsql} || logerr "mv pgsql"
logcmd cp ${DESTDIR}_mariadb/$PREFIX/sbin/zabbix_server \
    $DESTDIR/$PREFIX/sbin/zabbix_server.mariadb || logerr "cp mariadb"

for f in agent server; do
    xform files/$PROG-$f.xml > $TMPDIR/$PROG-$f.xml
    install_smf application $PROG-$f.xml
done

add_notes README.server-install

build_manifests
PKG=$PKG-agent make_package -seed $TMPDIR/mf.agent agent.mog
PKG=$PKG-server make_package -seed $TMPDIR/mf.server server.mog

clean_up

# Vim hints
# vim:ts=4:sw=4:et:fdm=marker
