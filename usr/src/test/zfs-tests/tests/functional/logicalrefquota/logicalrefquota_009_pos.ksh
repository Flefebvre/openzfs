#!/bin/ksh -p
#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#

#
# Copyright 2008 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#

#
# Copyright (c) 2013 by Delphix. All rights reserved.
#

. $STF_SUITE/include/libtest.shlib
. $STF_SUITE/tests/functional/logicalrefquota/logicalrefquota.kshlib

#
# DESCRIPTION:
#	Sub-filesystem quotas are not enforced by property 'logicalrefquota'
#
# STRATEGY:
#	1. Setting logicalquota and logicalrefquota for parent. lrefquota < lquota
#	2. Verify sub-filesystem will not be limited by logicalrefquota
#	3. Verify sub-filesystem will only be limited by logicalquota
#

verify_runnable "both"

function cleanup
{
	log_must $ZFS destroy -rf $TESTPOOL/$TESTFS
	log_must $ZFS create $TESTPOOL/$TESTFS
	log_must $ZFS set mountpoint=$TESTDIR $TESTPOOL/$TESTFS
}

log_assert "Sub-filesystem quotas are not enforced by property 'logicalrefquota'"
log_onexit cleanup

fs=$TESTPOOL/$TESTFS
log_must $ZFS set logicalquota=25M $fs
log_must $ZFS set logicalrefquota=10M $fs
log_must $ZFS set compression=on $fs
log_must $ZFS create $fs/subfs
log_must $ZFS set compression=on $fs/subfs

mntpnt=$(get_prop mountpoint $fs/subfs)
# fill a file of the size 20M
log_must fill_file $mntpnt/$TESTFILE1 20000000

typeset -i logicalused logicalquota logicalrefquota
logicalused=$(get_prop logicalused $fs)
logicalrefquota=$(get_prop logicalrefquota $fs)
((logicalused = logicalused / (1024 * 1024)))
((logicalrefquota = logicalrefquota / (1024 * 1024)))
if [[ $logicalused -lt $logicalrefquota ]]; then
	log_fail "ERROR: $logicalused < $logicalrefquota subfs quotas are limited by logicalrefquota"
fi

log_mustnot fill_file $mntpnt/$TESTFILE2 20000000
logicalused=$(get_prop logicalused $fs)
logicalquota=$(get_prop logicalquota $fs)
((logicalused = logicalused / (1024 * 1024)))
((logicalquota = logicalquota / (1024 * 1024)))
if [[ $logicalused -gt $logicalquota ]]; then
	log_fail "ERROR: $logicalused > $logicalquota subfs logicalquotas aren't limited by logicalquota"
fi

log_pass "Sub-filesystem logicalquotas are not enforced by property 'logicalrefquota'"
