#!/bin/ksh -p
# SPDX-License-Identifier: CDDL-1.0
#
# This file and its contents are supplied under the terms of the
# Common Development and Distribution License ("CDDL"), version 1.0.
# You may only use this file in accordance with the terms of version
# 1.0 of the CDDL.
#
# A full copy of the text of the CDDL should have accompanied this
# source.  A copy of the CDDL is also available via the Internet at
# https://opensource.org/license/CDDL-1.0.
#

. $STF_SUITE/include/libtest.shlib

#
# DESCRIPTION:
#
# Pool readonly=off remounts nested filesystems writable without
# changing a dataset readonly property, mounting a canmount=noauto
# dataset, or making a snapshot writable.
#
# STRATEGY:
# 1. Create a parent, a child, a readonly dataset, and a canmount=noauto
#    dataset, and take a snapshot
# 2. Set the pool readonly, then writable
# 3. Parent and child accept writes and keep their old files
# 4. The readonly dataset property is still on and writes fail
# 5. The canmount=noauto dataset stays unmounted
# 6. The snapshot directory stays readable and rejects writes
#

verify_runnable "global"

function cleanup
{
	if poolexists $TESTPOOL1; then
		zpool set readonly=off $TESTPOOL1 || \
		    log_note "could not clear readonly on $TESTPOOL1"
	fi
	destroy_pool $TESTPOOL1
	rm -f $DATA
}

log_assert "pool readonly=off does not change dataset mount policy"
log_onexit cleanup

DATA="$TEST_BASE_DIR/zpool_set_readonly_014_pos.$$.data"
PARENT=$TESTPOOL1/parent
CHILD=$PARENT/child
KEEP=$TESTPOOL1/keep
NOAUTO=$TESTPOOL1/noauto

log_must truncate -s $MINVDEVSIZE $DATA
log_must zpool create -O canmount=off $TESTPOOL1 $DATA
log_must zfs create -o snapdir=visible $PARENT
log_must zfs create $CHILD
log_must zfs create $KEEP
log_must zfs set readonly=on $KEEP
log_must zfs create -o canmount=noauto $NOAUTO

PMNT="$(get_prop mountpoint $PARENT)"
CMNT="$(get_prop mountpoint $CHILD)"
KMNT="$(get_prop mountpoint $KEEP)"

log_must eval "echo parent-file > $PMNT/parent-file"
log_must eval "echo child-file > $CMNT/child-file"
log_must zfs snapshot $PARENT@snap
log_mustnot ismounted $NOAUTO
log_must test -d $PMNT/.zfs/snapshot/snap
log_must grep -q parent-file $PMNT/.zfs/snapshot/snap/parent-file

log_must zpool set readonly=on $TESTPOOL1
log_mustnot eval "echo denied > $PMNT/denied"
log_mustnot eval "echo denied > $CMNT/denied"
log_must zpool set readonly=off $TESTPOOL1

log_must eval "echo parent-again > $PMNT/parent-again"
log_must eval "echo child-again > $CMNT/child-again"
log_must grep -q parent-file $PMNT/parent-file
log_must grep -q child-file $CMNT/child-file
log_must test "$(get_prop readonly $PARENT)" == "off"
log_must test "$(get_prop readonly $CHILD)" == "off"

log_must test "$(get_prop readonly $KEEP)" == "on"
log_mustnot eval "echo denied > $KMNT/denied"
log_mustnot ismounted $NOAUTO
log_must grep -q parent-file $PMNT/.zfs/snapshot/snap/parent-file
log_mustnot eval "echo denied > $PMNT/.zfs/snapshot/snap/denied"
log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "off"

log_pass "pool readonly=off does not change dataset mount policy"
