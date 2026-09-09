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
# File contents and allocated space survive both ways of switching
# a pool to readonly and back: the property, and a readonly import.
#
# STRATEGY:
# 1. Write a file, record its checksum and allocated space, sync
# 2. Set readonly=on, export, and import normally
# 3. Verify the checksum and that allocated space did not shrink or jump
# 4. Export, import -o readonly=on, set readonly=off, and write another file
# 5. Export, import normally, and verify both checksums
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

function allocated
{
	zpool list -Hp -o allocated $TESTPOOL1
}

log_assert "allocated space and file data survive readonly switches"
log_onexit cleanup

DATA="$TEST_BASE_DIR/zpool_set_readonly_012_pos.$$.data"
# A few megabytes of slack for import metadata, not a missing metaslab.
typeset -r slack=$((8 * 1024 * 1024))

log_must truncate -s $MINVDEVSIZE $DATA
log_must zpool create -O canmount=off $TESTPOOL1 $DATA
log_must zfs create $TESTPOOL1/$TESTFS
MNT="$(get_prop mountpoint $TESTPOOL1/$TESTFS)"

log_must dd if=/dev/urandom of=$MNT/first bs=1M count=8
log_must zpool sync $TESTPOOL1
sum1=$(cksum $MNT/first)
before=$(allocated)

log_must zpool set readonly=on $TESTPOOL1
log_must_busy zpool export $TESTPOOL1
log_must zpool import -d $TEST_BASE_DIR $TESTPOOL1
MNT="$(get_prop mountpoint $TESTPOOL1/$TESTFS)"
log_must test "$(cksum $MNT/first)" == "$sum1"
log_must zpool sync $TESTPOOL1
after=$(allocated)
if ((after < before || after > before + slack)); then
	log_fail "allocated changed from $before to $after after readonly export"
fi
log_must check_pool_status $TESTPOOL1 "errors" "No known data errors"

log_must_busy zpool export $TESTPOOL1
log_must zpool import -d $TEST_BASE_DIR -o readonly=on $TESTPOOL1
MNT="$(get_prop mountpoint $TESTPOOL1/$TESTFS)"
log_must test "$(cksum $MNT/first)" == "$sum1"
log_must zpool set readonly=off $TESTPOOL1
log_must dd if=/dev/urandom of=$MNT/second bs=1M count=4
log_must zpool sync $TESTPOOL1
sum2=$(cksum $MNT/second)
before=$(allocated)

log_must_busy zpool export $TESTPOOL1
log_must zpool import -d $TEST_BASE_DIR $TESTPOOL1
MNT="$(get_prop mountpoint $TESTPOOL1/$TESTFS)"
log_must test "$(cksum $MNT/first)" == "$sum1"
log_must test "$(cksum $MNT/second)" == "$sum2"
log_must zpool sync $TESTPOOL1
after=$(allocated)
if ((after < before || after > before + slack)); then
	log_fail "allocated changed from $before to $after after writable import"
fi
log_must check_pool_status $TESTPOOL1 "errors" "No known data errors"

log_pass "allocated space and file data survive readonly switches"
