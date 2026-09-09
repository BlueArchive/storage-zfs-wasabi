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
# A spare and a cache device opened by a readonly import are usable
# after readonly=off. Replacing onto the spare succeeds, and both
# devices are still listed after the pool is made readonly again.
#
# STRATEGY:
# 1. Create a pool with a spare and a cache device
# 2. Import it readonly, then set readonly=off
# 3. Replace the data disk with the spare and wait for it
# 4. Set readonly=on and verify writes fail while spare and cache remain
# 5. Set readonly=off and verify a write succeeds
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
	rm -f $DATA $SPARE $CACHE
}

log_assert "spare replace works after a readonly import is made writable"
log_onexit cleanup

DATA="$TEST_BASE_DIR/zpool_set_readonly_011_pos.$$.data"
SPARE="$TEST_BASE_DIR/zpool_set_readonly_011_pos.$$.spare"
CACHE="$TEST_BASE_DIR/zpool_set_readonly_011_pos.$$.cache"

log_must truncate -s $MINVDEVSIZE $DATA $SPARE $CACHE
log_must zpool create -O canmount=off $TESTPOOL1 $DATA spare $SPARE cache $CACHE
log_must zfs create $TESTPOOL1/$TESTFS
MNT="$(get_prop mountpoint $TESTPOOL1/$TESTFS)"
log_must eval "echo spare-before > $MNT/before"
log_must zpool sync $TESTPOOL1

log_must_busy zpool export $TESTPOOL1
log_must zpool import -d $TEST_BASE_DIR -o readonly=on $TESTPOOL1
log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "on"
log_must eval "zpool status -P $TESTPOOL1 | grep -F $SPARE"
log_must eval "zpool status -P $TESTPOOL1 | grep -F $CACHE"

log_must zpool set readonly=off $TESTPOOL1
log_must zpool replace $TESTPOOL1 $DATA $SPARE
log_must zpool wait -t replace $TESTPOOL1
log_must eval "zpool status -P $TESTPOOL1 | grep -F $SPARE"
log_must eval "zpool status -P $TESTPOOL1 | grep -F $CACHE"
log_must grep -q spare-before $MNT/before

log_must zpool set readonly=on $TESTPOOL1
log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "on"
log_mustnot eval "echo denied > $MNT/denied"
log_must eval "zpool status -P $TESTPOOL1 | grep -F $SPARE"
log_must eval "zpool status -P $TESTPOOL1 | grep -F $CACHE"

log_must zpool set readonly=off $TESTPOOL1
log_must eval "echo spare-after > $MNT/after"
log_must grep -q spare-after $MNT/after

log_pass "spare replace works after a readonly import is made writable"
