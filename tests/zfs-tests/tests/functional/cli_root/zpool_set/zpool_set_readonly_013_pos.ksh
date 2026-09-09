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
# Switching a pool to readonly and back restores a writable mount and
# keeps the mount options the filesystem was given. The dataset
# readonly property is left off.
#
# STRATEGY:
# 1. Mount a filesystem with several non-default options
# 2. Set the pool readonly and confirm the mount is read-only
# 3. Set the pool writable and confirm the original options remain,
#    rw is present, and ro is not a mount option
# 4. Confirm a write succeeds and atime=off is unchanged
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

function mount_options
{
	typeset mnt="$1"
	if is_linux; then
		awk -v m="$mnt" '$2 == m { print $4; exit }' /proc/mounts
	else
		mount -p | awk -v m="$mnt" '$2 == m { print $4; exit }'
	fi
}

function require_option
{
	typeset opts="$1"
	typeset token="$2"
	case ",$opts," in
	*",$token,"*) ;;
	*) log_fail "mount options '$opts' missing '$token'" ;;
	esac
}

function reject_option
{
	typeset opts="$1"
	typeset token="$2"
	case ",$opts," in
	*",$token,"*) log_fail "mount options '$opts' contain '$token'" ;;
	esac
}

log_assert "pool readonly=off restores rw and keeps mount options"
log_onexit cleanup

DATA="$TEST_BASE_DIR/zpool_set_readonly_013_pos.$$.data"
# norelatime is accepted by ZFS but is not a generic superblock flag, so
# Linux never prints it in /proc/mounts. Check only options that show up.
typeset opts="noatime,nodev,noexec,noxattr"

log_must truncate -s $MINVDEVSIZE $DATA
log_must zpool create -O canmount=off $TESTPOOL1 $DATA
log_must zfs create -o atime=off $TESTPOOL1/$TESTFS
log_must zfs unmount $TESTPOOL1/$TESTFS
log_must zfs mount -o $opts $TESTPOOL1/$TESTFS
MNT="$(get_prop mountpoint $TESTPOOL1/$TESTFS)"

before=$(mount_options $MNT)
require_option "$before" "rw"
reject_option "$before" "ro"
for token in noatime nodev noexec noxattr; do
	require_option "$before" "$token"
done

log_must zpool set readonly=on $TESTPOOL1
ropts=$(mount_options $MNT)
require_option "$ropts" "ro"
reject_option "$ropts" "rw"
log_mustnot eval "echo denied > $MNT/denied"

log_must zpool set readonly=off $TESTPOOL1
after=$(mount_options $MNT)
require_option "$after" "rw"
reject_option "$after" "ro"
for token in noatime nodev noexec noxattr; do
	require_option "$after" "$token"
done
log_must test "$(get_prop readonly $TESTPOOL1/$TESTFS)" == "off"
log_must test "$(get_prop atime $TESTPOOL1/$TESTFS)" == "off"
log_must eval "echo restored > $MNT/restored"
log_must grep -q restored $MNT/restored

log_pass "pool readonly=off restores rw and keeps mount options"
