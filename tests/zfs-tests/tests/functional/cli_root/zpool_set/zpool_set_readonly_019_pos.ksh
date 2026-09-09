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
# A pool imported readonly and rewound to its checkpoint cannot be made
# writable in place. The labels still hold a newer uberblock, so
# readonly=off is rejected. The pool stays read-only on the checkpointed
# tree, and a later import of the current tree still has the
# post-checkpoint data.
#
# STRATEGY:
# 1. Write a file, take a checkpoint, and overwrite the file
# 2. Export and import -o readonly=on --rewind-to-checkpoint
# 3. Verify the checkpointed contents
# 4. Confirm readonly=off is rejected and the tree stays read-only
# 5. Export and import the current tree and verify the later contents
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

log_assert "readonly=off is rejected on a checkpoint rewind"
log_onexit cleanup

DATA="$TEST_BASE_DIR/zpool_set_readonly_019_pos.$$.data"

log_must truncate -s $MINVDEVSIZE $DATA
log_must zpool create -O canmount=off $TESTPOOL1 $DATA
log_must zfs create $TESTPOOL1/$TESTFS
MNT="$(get_prop mountpoint $TESTPOOL1/$TESTFS)"

log_must eval "echo pre-checkpoint > $MNT/marker"
log_must zpool sync $TESTPOOL1
log_must zpool checkpoint $TESTPOOL1
log_must eval "echo post-checkpoint > $MNT/marker"
log_must zpool sync $TESTPOOL1
log_must_busy zpool export $TESTPOOL1

log_must zpool import -d $TEST_BASE_DIR -o readonly=on \
    --rewind-to-checkpoint $TESTPOOL1
MNT="$(get_prop mountpoint $TESTPOOL1/$TESTFS)"
log_must grep -qx pre-checkpoint $MNT/marker
log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "on"

log_mustnot zpool set readonly=off $TESTPOOL1
log_must grep -qx pre-checkpoint $MNT/marker
log_mustnot eval "echo writable-on-checkpoint >> $MNT/marker"
log_must grep -qx pre-checkpoint $MNT/marker
log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "on"

log_must_busy zpool export $TESTPOOL1
log_must zpool import -d $TEST_BASE_DIR $TESTPOOL1
MNT="$(get_prop mountpoint $TESTPOOL1/$TESTFS)"
log_must grep -qx post-checkpoint $MNT/marker
log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "off"

log_pass "readonly=off is rejected on a checkpoint rewind"
