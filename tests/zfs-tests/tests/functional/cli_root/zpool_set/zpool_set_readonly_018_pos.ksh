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
# A pool can be switched between readonly and writable several times
# in one session. Each generation of data is still there, and a final
# export and import returns the pool writable.
#
# STRATEGY:
# 1. Create a pool and a file
# 2. Five times, set readonly=on, confirm a write fails, set readonly=off,
#    and append a new line
# 3. Export and import and verify every line
#

verify_runnable "global"

function cleanup
{
	if poolexists $TESTPOOL1; then
		zpool set readonly=off $TESTPOOL1 || \
		    log_note "could not clear readonly on $TESTPOOL1"
	fi
	datasetexists $TESTPOOL1/$TESTFS && \
	    ismounted $TESTPOOL1/$TESTFS && \
	    log_must zfs unmount -f $TESTPOOL1/$TESTFS
	destroy_pool $TESTPOOL1
	rm -f $DATA
}

log_assert "repeated readonly=on/off cycles keep file data"
log_onexit cleanup

DATA="$TEST_BASE_DIR/zpool_set_readonly_018_pos.$$.data"

log_must truncate -s $MINVDEVSIZE $DATA
log_must zpool create -O canmount=off $TESTPOOL1 $DATA
log_must zfs create $TESTPOOL1/$TESTFS
MNT="$(get_prop mountpoint $TESTPOOL1/$TESTFS)"
log_must eval "echo generation-0 > $MNT/generations"

typeset -i i
for ((i = 1; i <= 5; i++)); do
	log_must zpool set readonly=on $TESTPOOL1
	log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "on"
	log_mustnot eval "echo denied > $MNT/denied"
	log_must grep -q generation-0 $MNT/generations
	log_must zpool set readonly=off $TESTPOOL1
	log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "off"
	log_must eval "echo generation-$i >> $MNT/generations"
done

log_must zpool sync $TESTPOOL1
log_must_busy zpool export $TESTPOOL1
log_must zpool import -d $TEST_BASE_DIR $TESTPOOL1
MNT="$(get_prop mountpoint $TESTPOOL1/$TESTFS)"
log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "off"
for ((i = 0; i <= 5; i++)); do
	log_must grep -q generation-$i $MNT/generations
done

log_pass "repeated readonly=on/off cycles keep file data"
