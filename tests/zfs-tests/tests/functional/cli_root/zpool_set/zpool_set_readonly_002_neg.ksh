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
# zpool create rejects readonly=on. The property is not persistent and
# cannot be set at creation.
#
# STRATEGY:
# 1. Verify zpool create -o readonly=on fails and does not leave a pool
#

verify_runnable "global"

function cleanup
{
	poolexists $TESTPOOL1 && destroy_pool $TESTPOOL1
	rm -f $FILEVDEV
}

log_assert "zpool create rejects readonly=on"
log_onexit cleanup

FILEVDEV="$TEST_BASE_DIR/zpool_set_readonly_002_neg.$$.dat"

log_must truncate -s $MINVDEVSIZE $FILEVDEV
log_mustnot zpool create -o readonly=on $TESTPOOL1 $FILEVDEV
log_mustnot poolexists $TESTPOOL1

log_pass "zpool create rejects readonly=on"
