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
# A zvol that is closed when the pool becomes readonly can be opened
# for read and cannot be opened for write. After readonly=off it
# accepts a write.
#
# STRATEGY:
# 1. Create a zvol and leave it closed
# 2. Set the pool readonly
# 3. Read the zvol and verify a write open fails
# 4. Set the pool writable and write a block
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

log_assert "a closed zvol opened after readonly=on rejects writes"
log_onexit cleanup

DATA="$TEST_BASE_DIR/zpool_set_readonly_015_pos.$$.data"
VOL=$TESTPOOL1/$TESTVOL
ZDEV=$ZVOL_DEVDIR/$VOL

log_must truncate -s $MINVDEVSIZE $DATA
log_must zpool create -O canmount=off $TESTPOOL1 $DATA
log_must zfs create -V 10m $VOL
block_device_wait $ZDEV

log_must zpool set readonly=on $TESTPOOL1
log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "on"
log_must dd if=$ZDEV of=/dev/null bs=512 count=1
log_mustnot dd if=/dev/zero of=$ZDEV bs=512 count=1 conv=notrunc

log_must zpool set readonly=off $TESTPOOL1
log_must dd if=/dev/zero of=$ZDEV bs=512 count=1 conv=notrunc
log_must dd if=$ZDEV of=/dev/null bs=512 count=1

log_pass "a closed zvol opened after readonly=on rejects writes"
