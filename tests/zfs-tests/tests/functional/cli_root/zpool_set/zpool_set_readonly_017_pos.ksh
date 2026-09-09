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
# A scrub that is in progress stays in progress across readonly=on
# and readonly=off, and does not report new data errors. Initialize
# can be started around the same switch and the pool stays writable.
#
# STRATEGY:
# 1. Suspend scrub progress and start a scrub
# 2. Set the pool readonly and back
# 3. Verify the scrub is still in progress and there are no data errors
# 4. Cancel the scrub, start initialize, and switch readonly again
# 5. Verify a write succeeds
#

verify_runnable "global"

function cleanup
{
	[[ -n $scan_save ]] && \
	    log_must set_tunable32 SCAN_SUSPEND_PROGRESS $scan_save
	if poolexists $TESTPOOL1; then
		zpool scrub -s $TESTPOOL1 || log_note "scrub not active"
		zpool initialize -c $TESTPOOL1 || \
		    log_note "initialize not active"
		zpool set readonly=off $TESTPOOL1 || \
		    log_note "could not clear readonly on $TESTPOOL1"
	fi
	datasetexists $TESTPOOL1/$TESTFS && \
	    ismounted $TESTPOOL1/$TESTFS && \
	    log_must zfs unmount -f $TESTPOOL1/$TESTFS
	destroy_pool $TESTPOOL1
	rm -f $DATA
}

log_assert "scrub survives a readonly switch and initialize can restart"
log_onexit cleanup

DATA="$TEST_BASE_DIR/zpool_set_readonly_017_pos.$$.data"
scan_save=$(get_tunable SCAN_SUSPEND_PROGRESS)

log_must truncate -s $MINVDEVSIZE $DATA
log_must zpool create -O canmount=off $TESTPOOL1 $DATA
log_must zfs create $TESTPOOL1/$TESTFS
MNT="$(get_prop mountpoint $TESTPOOL1/$TESTFS)"
log_must dd if=/dev/urandom of=$MNT/scrub-file bs=1M count=8
log_must zpool sync $TESTPOOL1

log_must set_tunable32 SCAN_SUSPEND_PROGRESS 1
log_must zpool scrub $TESTPOOL1
typeset -i i
for ((i = 0; i < 30; i++)); do
	is_pool_scrubbing $TESTPOOL1 && break
	sleep 1
done
is_pool_scrubbing $TESTPOOL1 || log_fail "scrub did not start"

log_must zpool set readonly=on $TESTPOOL1
log_must zpool set readonly=off $TESTPOOL1
is_pool_scrubbing $TESTPOOL1 || \
    log_fail "scrub was not still in progress after readonly=off"
log_must check_pool_status $TESTPOOL1 "errors" "No known data errors"
log_must zpool scrub -s $TESTPOOL1
log_must set_tunable32 SCAN_SUSPEND_PROGRESS $scan_save
scan_save=""

log_must zpool initialize $TESTPOOL1 $DATA
log_must zpool set readonly=on $TESTPOOL1
log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "on"
log_must zpool set readonly=off $TESTPOOL1
log_must zpool wait -t initialize $TESTPOOL1
log_must eval "echo after-initialize > $MNT/after"
log_must grep -q after-initialize $MNT/after
log_must check_pool_status $TESTPOOL1 "errors" "No known data errors"

log_pass "scrub survives a readonly switch and initialize can restart"
