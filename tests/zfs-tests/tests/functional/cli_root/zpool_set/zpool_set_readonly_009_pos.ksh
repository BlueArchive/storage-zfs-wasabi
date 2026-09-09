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
# A pool imported with readonly=on can be made writable with
# zpool set readonly=off. A slog and a special vdev stay present,
# and data written after the switch survives export and import.
#
# STRATEGY:
# 1. Create a pool with a slog and a special vdev and write a file
# 2. Export and import -o readonly=on
# 3. Verify writes fail, then set readonly=off
# 4. Write a second file, export, and import normally
# 5. Verify both files and that the slog and special vdev remain
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
	rm -f $DATA $LOG $SPECIAL
}

log_assert "import -o readonly=on then readonly=off keeps slog and special"
log_onexit cleanup

DATA="$TEST_BASE_DIR/zpool_set_readonly_009_pos.$$.data"
LOG="$TEST_BASE_DIR/zpool_set_readonly_009_pos.$$.log"
SPECIAL="$TEST_BASE_DIR/zpool_set_readonly_009_pos.$$.special"

log_must truncate -s $MINVDEVSIZE $DATA $LOG $SPECIAL
log_must zpool create -O canmount=off $TESTPOOL1 $DATA log $LOG special $SPECIAL
log_must zfs create $TESTPOOL1/$TESTFS
MNT="$(get_prop mountpoint $TESTPOOL1/$TESTFS)"

log_must eval "echo before-switch > $MNT/before"
log_must zpool sync $TESTPOOL1
log_must_busy zpool export $TESTPOOL1
log_must zpool import -d $TEST_BASE_DIR -o readonly=on $TESTPOOL1

log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "on"
log_must grep -q before-switch $MNT/before
log_mustnot eval "echo denied > $MNT/denied"

log_must zpool set readonly=off $TESTPOOL1
log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "off"
log_must test "$(get_pool_prop health $TESTPOOL1)" == "ONLINE"
log_must eval "zpool status -P $TESTPOOL1 | grep -F $LOG"
log_must eval "zpool status -P $TESTPOOL1 | grep -F $SPECIAL"
log_must eval "echo after-switch > $MNT/after"
log_must zpool sync $TESTPOOL1

log_must_busy zpool export $TESTPOOL1
log_must zpool import -d $TEST_BASE_DIR $TESTPOOL1
log_must grep -q before-switch $MNT/before
log_must grep -q after-switch $MNT/after
log_must eval "zpool status -P $TESTPOOL1 | grep -F $LOG"
log_must eval "zpool status -P $TESTPOOL1 | grep -F $SPECIAL"

log_pass "import -o readonly=on then readonly=off keeps slog and special"
