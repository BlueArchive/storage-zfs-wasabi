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
# A raidz pool imported with readonly=on can be made writable with
# zpool set readonly=off, and data written afterward survives a
# normal export and import.
#
# STRATEGY:
# 1. Create a raidz pool and write a file
# 2. Export and import -o readonly=on
# 3. Set readonly=off, write a second file, export, and import
# 4. Verify both files and that the pool is still raidz
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
	rm -f $D1 $D2 $D3
}

log_assert "import -o readonly=on then readonly=off works on raidz"
log_onexit cleanup

D1="$TEST_BASE_DIR/zpool_set_readonly_010_pos.$$.1"
D2="$TEST_BASE_DIR/zpool_set_readonly_010_pos.$$.2"
D3="$TEST_BASE_DIR/zpool_set_readonly_010_pos.$$.3"

log_must truncate -s $MINVDEVSIZE $D1 $D2 $D3
log_must zpool create -O canmount=off $TESTPOOL1 raidz $D1 $D2 $D3
log_must zfs create $TESTPOOL1/$TESTFS
MNT="$(get_prop mountpoint $TESTPOOL1/$TESTFS)"

log_must eval "echo raidz-before > $MNT/before"
log_must zpool sync $TESTPOOL1
log_must_busy zpool export $TESTPOOL1
log_must zpool import -d $TEST_BASE_DIR -o readonly=on $TESTPOOL1

log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "on"
log_mustnot eval "echo denied > $MNT/denied"
log_must zpool set readonly=off $TESTPOOL1
log_must eval "zpool status $TESTPOOL1 | grep -q raidz"
log_must eval "echo raidz-after > $MNT/after"
log_must zpool sync $TESTPOOL1

log_must_busy zpool export $TESTPOOL1
log_must zpool import -d $TEST_BASE_DIR $TESTPOOL1
log_must test "$(get_pool_prop health $TESTPOOL1)" == "ONLINE"
log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "off"
log_must grep -q raidz-before $MNT/before
log_must grep -q raidz-after $MNT/after
log_must eval "zpool status $TESTPOOL1 | grep -q raidz"

log_pass "import -o readonly=on then readonly=off works on raidz"
