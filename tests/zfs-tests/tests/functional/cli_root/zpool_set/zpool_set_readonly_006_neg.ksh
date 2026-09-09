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
# A failed readonly=off on a pool imported read-only leaves the pool
# readable, keeps its spare and cache devices, and can be exported
# and imported again.
#
# STRATEGY:
# 1. Create a pool with a slog, a spare, and a cache device
# 2. Import it readonly and inject I/O errors on the data vdev
# 3. Verify readonly=off fails and the pool is still readonly
# 4. Clear the injection and verify the file, spare, cache, and
#    allocated space
# 5. Export and import and read the file again
#

verify_runnable "global"

function cleanup
{
	zinject -c all || log_note "no fault injection to clear"
	if poolexists $TESTPOOL1; then
		zpool set readonly=off $TESTPOOL1 || \
		    log_note "could not clear readonly on $TESTPOOL1"
	fi
	datasetexists $TESTPOOL1/$TESTFS && \
	    ismounted $TESTPOOL1/$TESTFS && \
	    log_must zfs unmount -f $TESTPOOL1/$TESTFS
	destroy_pool $TESTPOOL1
	rm -f $DATA $LOG $SPARE $CACHE
}

log_assert "failed readonly=off leaves an imported-readonly pool readable"
log_onexit cleanup

DATA="$TEST_BASE_DIR/zpool_set_readonly_006_neg.$$.data"
LOG="$TEST_BASE_DIR/zpool_set_readonly_006_neg.$$.log"
SPARE="$TEST_BASE_DIR/zpool_set_readonly_006_neg.$$.spare"
CACHE="$TEST_BASE_DIR/zpool_set_readonly_006_neg.$$.cache"

log_must truncate -s $MINVDEVSIZE $DATA
log_must truncate -s $MINVDEVSIZE $LOG
log_must truncate -s $MINVDEVSIZE $SPARE
log_must truncate -s $MINVDEVSIZE $CACHE
log_must zpool create -O canmount=off $TESTPOOL1 \
    $DATA log $LOG spare $SPARE cache $CACHE
log_must zpool set failmode=continue $TESTPOOL1
log_must zfs create $TESTPOOL1/$TESTFS
MNT="$(get_prop mountpoint $TESTPOOL1/$TESTFS)"
log_must eval "echo still-readable > $MNT/file"
log_must zpool sync $TESTPOOL1

log_must_busy zpool export $TESTPOOL1
log_must zpool import -d $TEST_BASE_DIR -o readonly=on $TESTPOOL1
MNT="$(get_prop mountpoint $TESTPOOL1/$TESTFS)"
log_must grep -q still-readable $MNT/file
before=$(zpool list -Hp -o allocated $TESTPOOL1)

log_must zinject -d $DATA -e io -T all -f 100 $TESTPOOL1
log_mustnot zpool set readonly=off $TESTPOOL1
log_must zinject -c all

log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "on"
log_must grep -q still-readable $MNT/file
after=$(zpool list -Hp -o allocated $TESTPOOL1)
if [[ $before != "$after" ]]; then
	log_fail "allocated changed from $before to $after"
fi
log_must eval "zpool status -P $TESTPOOL1 | grep -F $SPARE"
log_must eval "zpool status -P $TESTPOOL1 | grep -F $CACHE"
log_must eval "zpool status -P $TESTPOOL1 | grep -F $LOG"

log_must_busy zpool export $TESTPOOL1
log_must zpool import -d $TEST_BASE_DIR $TESTPOOL1
MNT="$(get_prop mountpoint $TESTPOOL1/$TESTFS)"
log_must grep -q still-readable $MNT/file
log_must test "$(get_pool_prop health $TESTPOOL1)" == "ONLINE"

log_pass "failed readonly=off leaves an imported-readonly pool readable"
