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
# On a pool imported readonly, setting another property is rejected
# and does not change the pool. readonly=on is a no-op. readonly=off
# alone makes the pool writable.
#
# STRATEGY:
# 1. Import a pool with readonly=on
# 2. Verify comment and autoexpand cannot be set and stay unchanged
# 3. Verify readonly=on succeeds and the pool stays readonly
# 4. Verify readonly=off succeeds and a write works
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

log_assert "non-readonly properties are rejected on a readonly import"
log_onexit cleanup

DATA="$TEST_BASE_DIR/zpool_set_readonly_007_neg.$$.data"

log_must truncate -s $MINVDEVSIZE $DATA
log_must zpool create -O canmount=off $TESTPOOL1 $DATA
log_must zfs create $TESTPOOL1/$TESTFS
log_must zpool set comment=kept $TESTPOOL1
MNT="$(get_prop mountpoint $TESTPOOL1/$TESTFS)"
log_must eval "echo prop-file > $MNT/file"
log_must zpool sync $TESTPOOL1
autoexpand=$(get_pool_prop autoexpand $TESTPOOL1)

log_must_busy zpool export $TESTPOOL1
log_must zpool import -d $TEST_BASE_DIR -o readonly=on $TESTPOOL1
MNT="$(get_prop mountpoint $TESTPOOL1/$TESTFS)"
log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "on"

log_mustnot zpool set comment=blocked $TESTPOOL1
log_must test "$(get_pool_prop comment $TESTPOOL1)" == "kept"
log_mustnot zpool set autoexpand=on $TESTPOOL1
log_must test "$(get_pool_prop autoexpand $TESTPOOL1)" == "$autoexpand"
log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "on"

log_must zpool set readonly=on $TESTPOOL1
log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "on"
log_must grep -q prop-file $MNT/file

log_must zpool set readonly=off $TESTPOOL1
log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "off"
log_must test "$(get_pool_prop comment $TESTPOOL1)" == "kept"
log_must test "$(get_pool_prop autoexpand $TESTPOOL1)" == "$autoexpand"
log_must eval "echo prop-writable > $MNT/writable"
log_must grep -q prop-writable $MNT/writable

log_pass "non-readonly properties are rejected on a readonly import"
