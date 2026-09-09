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
# An encrypted dataset with its key loaded survives a pool readonly
# switch. After the key is unloaded and the ZIL has been synced, the
# switch still succeeds and the data is readable once the key is loaded.
#
# STRATEGY:
# 1. Create an encrypted filesystem, write a file, and sync
# 2. Set the pool readonly and back, and read the file
# 3. Unmount, unload the key, and switch readonly again
# 4. Load the key, mount, and read the file
#

verify_runnable "global"

function cleanup
{
	if poolexists $TESTPOOL1; then
		zpool set readonly=off $TESTPOOL1 || \
		    log_note "could not clear readonly on $TESTPOOL1"
	fi
	datasetexists $FS && ismounted $FS && \
	    log_must zfs unmount -f $FS
	destroy_pool $TESTPOOL1
	rm -f $DATA
}

log_assert "encrypted datasets survive pool readonly switches"
log_onexit cleanup

DATA="$TEST_BASE_DIR/zpool_set_readonly_016_pos.$$.data"
FS=$TESTPOOL1/$TESTFS

log_must truncate -s $MINVDEVSIZE $DATA
log_must zpool create -O canmount=off $TESTPOOL1 $DATA
log_must eval "echo 'password' | zfs create -o encryption=on \
	-o keyformat=passphrase -o keylocation=prompt $FS"
MNT="$(get_prop mountpoint $FS)"
log_must eval "echo encrypted-data > $MNT/secret"
log_must zpool sync $TESTPOOL1

log_must zpool set readonly=on $TESTPOOL1
log_must grep -q encrypted-data $MNT/secret
log_mustnot eval "echo denied > $MNT/denied"
log_must zpool set readonly=off $TESTPOOL1
log_must grep -q encrypted-data $MNT/secret
log_must eval "echo encrypted-more > $MNT/more"

log_must zpool sync $TESTPOOL1
log_must zfs unmount $FS
log_must zfs unload-key $FS
log_must zpool set readonly=on $TESTPOOL1
log_must test "$(get_pool_prop readonly $TESTPOOL1)" == "on"
log_must zpool set readonly=off $TESTPOOL1
log_must eval "echo 'password' | zfs load-key $FS"
log_must zfs mount $FS
log_must grep -q encrypted-data $MNT/secret
log_must grep -q encrypted-more $MNT/more

log_pass "encrypted datasets survive pool readonly switches"
