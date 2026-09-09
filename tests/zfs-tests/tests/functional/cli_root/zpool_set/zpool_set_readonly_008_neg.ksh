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
# zpool set readonly=on is rejected while a device removal or a raidz
# expansion is in progress, and the pool stays writable.
#
# STRATEGY:
# 1. Suspend removal progress, start removing a disk, and verify
#    readonly=on fails and a write still succeeds
# 2. Cancel the removal while it is still suspended, then clear the
#    suspend tunable
# 3. Pause raidz expansion, attach a disk, and verify readonly=on
#    fails and a write still succeeds
# 4. Let the expansion finish
#

verify_runnable "global"

function cleanup
{
	# Unpause background work before tearing the pool down, then put
	# the tunables back to whatever the host was using.
	[[ -n $removal_save ]] && \
	    log_must set_tunable32 REMOVAL_SUSPEND_PROGRESS 0
	[[ -n $raidz_save ]] && \
	    log_must set_tunable64 RAIDZ_EXPAND_MAX_REFLOW_BYTES 0
	if poolexists $TESTPOOL1; then
		zpool remove -s $TESTPOOL1 || log_note "no removal to stop"
		zpool set readonly=off $TESTPOOL1 || \
		    log_note "could not clear readonly on $TESTPOOL1"
	fi
	datasetexists $TESTPOOL1/$TESTFS && \
	    ismounted $TESTPOOL1/$TESTFS && \
	    log_must zfs unmount -f $TESTPOOL1/$TESTFS
	destroy_pool $TESTPOOL1
	rm -f $D1 $D2 $R1 $R2 $R3 $R4
	[[ -n $removal_save ]] && \
	    log_must set_tunable32 REMOVAL_SUSPEND_PROGRESS $removal_save
	[[ -n $raidz_save ]] && \
	    log_must set_tunable64 RAIDZ_EXPAND_MAX_REFLOW_BYTES $raidz_save
}

function wait_expand_paused
{
	typeset oldcopied="" newcopied=""
	typeset -i i=0

	while ((i < 30)); do
		# Expansion status is "N / M copied at ...". "copied out of" is
		# the device-removal line and never appears here.
		newcopied=$(zpool status $TESTPOOL1 | \
		    awk '/copied at/ { print $1; exit }')
		if [[ -n $newcopied && $newcopied == "$oldcopied" ]]; then
			log_note "raidz expand paused at $newcopied"
			return 0
		fi
		oldcopied=$newcopied
		sleep 2
		((i = i + 1))
	done
	log_fail "raidz expand did not pause"
}

log_assert "readonly=on is rejected during removal and raidz expansion"
log_onexit cleanup

removal_save=$(get_tunable REMOVAL_SUSPEND_PROGRESS)
raidz_save=$(get_tunable RAIDZ_EXPAND_MAX_REFLOW_BYTES)

D1="$TEST_BASE_DIR/zpool_set_readonly_008_neg.$$.d1"
D2="$TEST_BASE_DIR/zpool_set_readonly_008_neg.$$.d2"
R1="$TEST_BASE_DIR/zpool_set_readonly_008_neg.$$.r1"
R2="$TEST_BASE_DIR/zpool_set_readonly_008_neg.$$.r2"
R3="$TEST_BASE_DIR/zpool_set_readonly_008_neg.$$.r3"
R4="$TEST_BASE_DIR/zpool_set_readonly_008_neg.$$.r4"

log_must truncate -s $MINVDEVSIZE $D1
log_must truncate -s $MINVDEVSIZE $D2
log_must zpool create -O canmount=off $TESTPOOL1 $D1 $D2
log_must zfs create $TESTPOOL1/$TESTFS
MNT="$(get_prop mountpoint $TESTPOOL1/$TESTFS)"
log_must dd if=/dev/zero of=$MNT/remove-file bs=1M count=8
log_must zpool sync $TESTPOOL1

log_must set_tunable32 REMOVAL_SUSPEND_PROGRESS 1
log_must zpool remove $TESTPOOL1 $D2
typeset -i i
for ((i = 0; i < 30; i++)); do
	is_pool_removing $TESTPOOL1 && break
	sleep 1
done
is_pool_removing $TESTPOOL1 || log_fail "removal did not start"
log_mustnot zpool set readonly=on $TESTPOOL1
log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "off"
log_must eval "echo still-writable > $MNT/still"

# Cancel before clearing the pause. Clearing it first lets an 8MB
# removal finish, and remove -s then fails with nothing to cancel.
log_must zpool remove -s $TESTPOOL1
log_must set_tunable32 REMOVAL_SUSPEND_PROGRESS 0
destroy_pool $TESTPOOL1

log_must truncate -s $MINVDEVSIZE $R1
log_must truncate -s $MINVDEVSIZE $R2
log_must truncate -s $MINVDEVSIZE $R3
log_must truncate -s $MINVDEVSIZE $R4
log_must zpool create -O canmount=off $TESTPOOL1 raidz $R1 $R2 $R3
log_must zfs create $TESTPOOL1/$TESTFS
MNT="$(get_prop mountpoint $TESTPOOL1/$TESTFS)"
log_must dd if=/dev/zero of=$MNT/expand-file bs=1M count=8
log_must zpool sync $TESTPOOL1

raid=$(zpool status $TESTPOOL1 | awk '/raidz/ { print $1; exit }')
[[ -n $raid ]] || log_fail "raidz vdev not found"
log_must set_tunable64 RAIDZ_EXPAND_MAX_REFLOW_BYTES 1
log_must zpool attach $TESTPOOL1 $raid $R4
wait_expand_paused
log_mustnot zpool set readonly=on $TESTPOOL1
log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "off"
log_must eval "echo expand-writable > $MNT/expand-writable"

log_must set_tunable64 RAIDZ_EXPAND_MAX_REFLOW_BYTES 0
log_must zpool wait -t raidz_expand $TESTPOOL1
log_must test "$(get_pool_prop health $TESTPOOL1)" == "ONLINE"

log_pass "readonly=on is rejected during removal and raidz expansion"
