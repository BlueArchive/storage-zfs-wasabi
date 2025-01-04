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
# http://www.illumos.org/license/CDDL.
#

#
# Copyright 2017, loli10K <ezomori.nozomu@gmail.com>. All rights reserved.
#

. $STF_SUITE/include/libtest.shlib
. $STF_SUITE/tests/functional/cli_root/zpool_events/zpool_events.kshlib

#
# DESCRIPTION:
# 'zpool events -c' should successfully clear events.
#
# STRATEGY:
# 1. Clear all ZFS events
# 2. Generate some new ZFS events
# 3. Verify 'zpool events -c' successfully clears new events
#

verify_runnable "both"

log_assert "'zpool events -c' should successfully clear events."

# 1. Clear all ZFS events
# This is needed because we may already over the max number or events queued
# (zfs_zevent_len_max) generated by previous tests: generating $EVENTS_NUM new
# events and then counting them is racy and leads to failures, so start from 0.
log_must zpool events -c

# 2. Generate some new ZFS events
for i in `seq 1 $EVENTS_NUM`; do
	log_must zpool clear $TESTPOOL
done
# wait a bit to allow the kernel module to process new events
zpool_events_settle
EVENTS_NUM=$(zpool events -H | wc -l)
EVENTS_NUM=${EVENTS_NUM##* }

# 3. Verify 'zpool events -c' successfully clear new events
CLEAR_OUTPUT=$(zpool events -c)
if [[ "$CLEAR_OUTPUT" != "cleared $EVENTS_NUM events" ]]; then
	log_fail "Failed to clear $EVENTS_NUM events: $CLEAR_OUTPUT"
fi
EVENTS_NUM=$(zpool events -H | wc -l)
if [[ $EVENTS_NUM -ne 0 ]];  then
	log_fail "Unexpected events number: $EVENTS_NUM != 0"
fi

log_pass "'zpool events -c' successfully clears events."
