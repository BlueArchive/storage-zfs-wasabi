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
# A pool imported read-write can be switched to readonly and back with
# zpool set, and writes work again afterward.
#
# STRATEGY:
# 1. Create a pool, write a file, and set readonly=on
# 2. Verify the command succeeds, the pool is readonly, and writes fail
# 3. Set readonly=off and verify writes succeed without losing the file
# 4. Setting readonly=off again on the writable pool is a no-op
#

verify_runnable "global"

function cleanup
{
	datasetexists $TESTPOOL1/$TESTFS && \
	    ismounted $TESTPOOL1/$TESTFS && \
	    log_must zfs unmount -f $TESTPOOL1/$TESTFS
	destroy_pool $TESTPOOL1
	rm -f $FILEVDEV
}

log_assert "zpool set readonly=on/off switches an imported pool"
log_onexit cleanup

FILEVDEV="$TEST_BASE_DIR/zpool_set_readonly_008.$$.dat"
TESTFILE="readonly-roundtrip-file"
CONTENT="zpool_set_readonly_008"

log_must truncate -s $MINVDEVSIZE $FILEVDEV
log_must zpool create -O canmount=off $TESTPOOL1 $FILEVDEV
log_must zfs create $TESTPOOL1/$TESTFS
MNTPFS="$(get_prop mountpoint $TESTPOOL1/$TESTFS)"

log_must eval "echo $CONTENT > $MNTPFS/$TESTFILE"

log_must zpool set readonly=off $TESTPOOL1
log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "off"

log_must zpool set readonly=on $TESTPOOL1
log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "on"
log_must test "$(get_prop readonly $TESTPOOL1/$TESTFS)" == "on"
log_must test "$(cat $MNTPFS/$TESTFILE)" == "$CONTENT"
log_mustnot touch $MNTPFS/$TESTFILE.new
log_mustnot zfs create $TESTPOOL1/${TESTFS}_new

log_must zpool set readonly=off $TESTPOOL1
log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "off"
log_must test "$(get_prop readonly $TESTPOOL1/$TESTFS)" == "off"
log_must test "$(cat $MNTPFS/$TESTFILE)" == "$CONTENT"
log_must eval "echo rewritten > $MNTPFS/$TESTFILE.new"
log_must test "$(cat $MNTPFS/$TESTFILE.new)" == "rewritten"
log_must zfs create $TESTPOOL1/${TESTFS}_new

log_must zpool set readonly=off $TESTPOOL1
log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "off"

log_pass "zpool set readonly=on/off switches an imported pool"
