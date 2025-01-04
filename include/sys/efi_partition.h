// SPDX-License-Identifier: CDDL-1.0
/*
 * CDDL HEADER START
 *
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License (the "License").
 * You may not use this file except in compliance with the License.
 *
 * You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
 * or https://opensource.org/licenses/CDDL-1.0.
 * See the License for the specific language governing permissions
 * and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL HEADER in each
 * file and include the License file at usr/src/OPENSOLARIS.LICENSE.
 * If applicable, add the following below this CDDL HEADER, with the
 * fields enclosed by brackets "[]" replaced with your own identifying
 * information: Portions Copyright [yyyy] [name of copyright owner]
 *
 * CDDL HEADER END
 */
/*
 * Copyright (c) 2002, 2010, Oracle and/or its affiliates. All rights reserved.
 * Copyright 2012 Nexenta Systems, Inc.  All rights reserved.
 */

#ifndef	_SYS_EFI_PARTITION_H
#define	_SYS_EFI_PARTITION_H extern __attribute__((visibility("default")))

#include <sys/uuid.h>

#ifdef	__cplusplus
extern "C" {
#endif

/*
 * GUID Partition Table Header
 */

#define	EFI_MIN_LABEL_SIZE 92
#define	EFI_LABEL_SIZE	512
#define	LEN_EFI_PAD	(EFI_LABEL_SIZE - \
			    ((5 * sizeof (diskaddr_t)) + \
			    (7 * sizeof (uint_t)) + \
			    (8 * sizeof (char)) + \
			    (1 * (sizeof (struct uuid)))))

#define	EFI_SIGNATURE	0x5452415020494645ULL

/* EFI Guid Partition Table Header -- little endian on-disk format */
typedef struct efi_gpt {
	uint64_t	efi_gpt_Signature;
	uint_t		efi_gpt_Revision;
	uint_t		efi_gpt_HeaderSize;
	uint_t		efi_gpt_HeaderCRC32;
	uint_t		efi_gpt_Reserved1;
	diskaddr_t	efi_gpt_MyLBA;
	diskaddr_t	efi_gpt_AlternateLBA;
	diskaddr_t	efi_gpt_FirstUsableLBA;
	diskaddr_t	efi_gpt_LastUsableLBA;
	struct uuid	efi_gpt_DiskGUID;
	diskaddr_t	efi_gpt_PartitionEntryLBA;
	uint_t		efi_gpt_NumberOfPartitionEntries;
	uint_t		efi_gpt_SizeOfPartitionEntry;
	uint_t		efi_gpt_PartitionEntryArrayCRC32;
	char		efi_gpt_Reserved2[LEN_EFI_PAD];
} efi_gpt_t;

/* EFI Guid Partition Entry Attributes -- little endian format */
typedef struct efi_gpe_Attrs {
	uint32_t	PartitionAttrs		:16,
			Reserved2		:16;
	uint32_t	Reserved1		:31,
			RequiredPartition	:1;
} efi_gpe_Attrs_t;

/* MBR partition identification tags */
#define	V_UNASSIGNED	0x00		/* unassigned partition */
#define	V_USR		0x04		/* Usr filesystem */
#define	V_RESERVED	0x0b		/* SMI reserved data */

/*
 * 6a96237f-1dd2-11b2-99a6-080020736631	V_UNASSIGNED (not used as such)
 * 6a898cc3-1dd2-11b2-99a6-080020736631	V_USR
 * 6a945a3b-1dd2-11b2-99a6-080020736631	V_RESERVED
 */

#define	EFI_UNUSED		{ 0x00000000, 0x0000, 0x0000, 0x00, 0x00, \
				    { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 } }
#define	EFI_RESV1		{ 0x6a96237f, 0x1dd2, 0x11b2, 0x99, 0xa6, \
				    { 0x08, 0x00, 0x20, 0x73, 0x66, 0x31 } }
#define	EFI_BOOT		{ 0x6a82cb45, 0x1dd2, 0x11b2, 0x99, 0xa6, \
				    { 0x08, 0x00, 0x20, 0x73, 0x66, 0x31 } }
#define	EFI_ROOT		{ 0x6a85cf4d, 0x1dd2, 0x11b2, 0x99, 0xa6, \
				    { 0x08, 0x00, 0x20, 0x73, 0x66, 0x31 } }
#define	EFI_SWAP		{ 0x6a87c46f, 0x1dd2, 0x11b2, 0x99, 0xa6, \
				    { 0x08, 0x00, 0x20, 0x73, 0x66, 0x31 } }
#define	EFI_USR			{ 0x6a898cc3, 0x1dd2, 0x11b2, 0x99, 0xa6, \
				    { 0x08, 0x00, 0x20, 0x73, 0x66, 0x31 } }
#define	EFI_BACKUP		{ 0x6a8b642b, 0x1dd2, 0x11b2, 0x99, 0xa6, \
				    { 0x08, 0x00, 0x20, 0x73, 0x66, 0x31 } }
#define	EFI_RESV2		{ 0x6a8d2ac7, 0x1dd2, 0x11b2, 0x99, 0xa6, \
				    { 0x08, 0x00, 0x20, 0x73, 0x66, 0x31 } }
#define	EFI_VAR			{ 0x6a8ef2e9, 0x1dd2, 0x11b2, 0x99, 0xa6, \
				    { 0x08, 0x00, 0x20, 0x73, 0x66, 0x31 } }
#define	EFI_HOME		{ 0x6a90ba39, 0x1dd2, 0x11b2, 0x99, 0xa6, \
				    { 0x08, 0x00, 0x20, 0x73, 0x66, 0x31 } }
#define	EFI_ALTSCTR		{ 0x6a9283a5, 0x1dd2, 0x11b2, 0x99, 0xa6, \
				    { 0x08, 0x00, 0x20, 0x73, 0x66, 0x31 } }
#define	EFI_RESERVED		{ 0x6a945a3b, 0x1dd2, 0x11b2, 0x99, 0xa6, \
				    { 0x08, 0x00, 0x20, 0x73, 0x66, 0x31 } }
#define	EFI_SYSTEM		{ 0xC12A7328, 0xF81F, 0x11d2, 0xBA, 0x4B, \
				    { 0x00, 0xA0, 0xC9, 0x3E, 0xC9, 0x3B } }
#define	EFI_LEGACY_MBR		{ 0x024DEE41, 0x33E7, 0x11d3, 0x9D, 0x69, \
				    { 0x00, 0x08, 0xC7, 0x81, 0xF3, 0x9F } }
#define	EFI_SYMC_PUB		{ 0x6a9630d1, 0x1dd2, 0x11b2, 0x99, 0xa6, \
				    { 0x08, 0x00, 0x20, 0x73, 0x66, 0x31 } }
#define	EFI_SYMC_CDS		{ 0x6a980767, 0x1dd2, 0x11b2, 0x99, 0xa6, \
				    { 0x08, 0x00, 0x20, 0x73, 0x66, 0x31 } }
#define	EFI_MSFT_RESV		{ 0xE3C9E316, 0x0B5C, 0x4DB8, 0x81, 0x7D, \
				    { 0xF9, 0x2D, 0xF0, 0x02, 0x15, 0xAE } }
#define	EFI_DELL_BASIC		{ 0xebd0a0a2, 0xb9e5, 0x4433, 0x87, 0xc0, \
				    { 0x68, 0xb6, 0xb7, 0x26, 0x99, 0xc7 } }
#define	EFI_DELL_RAID		{ 0xa19d880f, 0x05fc, 0x4d3b, 0xa0, 0x06, \
				    { 0x74, 0x3f, 0x0f, 0x84, 0x91, 0x1e } }
#define	EFI_DELL_SWAP		{ 0x0657fd6d, 0xa4ab, 0x43c4, 0x84, 0xe5, \
				    { 0x09, 0x33, 0xc8, 0x4b, 0x4f, 0x4f } }
#define	EFI_DELL_LVM		{ 0xe6d6d379, 0xf507, 0x44c2, 0xa2, 0x3c, \
				    { 0x23, 0x8f, 0x2a, 0x3d, 0xf9, 0x28 } }
#define	EFI_DELL_RESV		{ 0x8da63339, 0x0007, 0x60c0, 0xc4, 0x36, \
				    { 0x08, 0x3a, 0xc8, 0x23, 0x09, 0x08 } }
#define	EFI_AAPL_HFS		{ 0x48465300, 0x0000, 0x11aa, 0xaa, 0x11, \
				    { 0x00, 0x30, 0x65, 0x43, 0xec, 0xac } }
#define	EFI_AAPL_UFS		{ 0x55465300, 0x0000, 0x11aa, 0xaa, 0x11, \
				    { 0x00, 0x30, 0x65, 0x43, 0xec, 0xac } }
#define	EFI_FREEBSD_BOOT	{ 0x83bd6b9d, 0x7f41, 0x11dc, 0xbe, 0x0b, \
				    { 0x00, 0x15, 0x60, 0xb8, 0x4f, 0x0f } }
#define	EFI_FREEBSD_SWAP	{ 0x516e7cb5, 0x6ecf, 0x11d6, 0x8f, 0xf8, \
				    { 0x00, 0x02, 0x2d, 0x09, 0x71, 0x2b } }
#define	EFI_FREEBSD_UFS		{ 0x516e7cb6, 0x6ecf, 0x11d6, 0x8f, 0xf8, \
				    { 0x00, 0x02, 0x2d, 0x09, 0x71, 0x2b } }
#define	EFI_FREEBSD_VINUM	{ 0x516e7cb8, 0x6ecf, 0x11d6, 0x8f, 0xf8, \
				    { 0x00, 0x02, 0x2d, 0x09, 0x71, 0x2b } }
#define	EFI_FREEBSD_ZFS		{ 0x516e7cba, 0x6ecf, 0x11d6, 0x8f, 0xf8, \
				    { 0x00, 0x02, 0x2d, 0x09, 0x71, 0x2b } }

/* From Wikipedia */

#define	EFI_BIOS_BOOT		{ 0x21686148, 0x6449, 0x6e6f, 0x74, 0x4e, \
				    { 0x65, 0x65, 0x64, 0x45, 0x46, 0x49 } }
#define	EFI_INTC_RS		{ 0xd3bfe2de, 0x3daf, 0x11df, 0xba, 0x40, \
				    { 0xe3, 0xa5, 0x56, 0xd8, 0x95, 0x93 } }
#define	EFI_SNE_BOOT		{ 0xf4019732, 0x066e, 0x4e12, 0x82, 0x73, \
				    { 0x34, 0x6c, 0x56, 0x41, 0x49, 0x4f } }
#define	EFI_LENOVO_BOOT		{ 0xbfbfafe7, 0xa34f, 0x448a, 0x9a, 0x5b, \
				    { 0x62, 0x13, 0xeb, 0x73, 0x6c, 0x22 } }
#define	EFI_MSFT_LDMM		{ 0x5808c8aa, 0x7e8f, 0x42e0, 0x85, 0xd2, \
				    { 0xe1, 0xe9, 0x04, 0x34, 0xcf, 0xb3 } }
#define	EFI_MSFT_LDMD		{ 0xaf9b60a0, 0x1431, 0x4f62, 0xbc, 0x68, \
				    { 0x33, 0x11, 0x71, 0x4a, 0x69, 0xad } }
#define	EFI_MSFT_RE		{ 0xde94bba4, 0x06d1, 0x4d40, 0xa1, 0x6a, \
				    { 0xbf, 0xd5, 0x01, 0x79, 0xd6, 0xac } }
#define	EFI_IBM_GPFS		{ 0x37affc90, 0xef7d, 0x4e96, 0x91, 0xc3, \
				    { 0x2d, 0x7a, 0xe0, 0x55, 0xb1, 0x74 } }
#define	EFI_MSFT_STORAGESPACES	{ 0xe75caf8f, 0xf680, 0x4cee, 0xaf, 0xa3, \
				    { 0xb0, 0x01, 0xe5, 0x6e, 0xfc, 0x2d } }
#define	EFI_HPQ_DATA		{ 0x75894c1e, 0x3aeb, 0x11d3, 0xb7, 0xc1, \
				    { 0x7b, 0x03, 0xa0, 0x00, 0x00, 0x00 } }
#define	EFI_HPQ_SVC		{ 0xe2a1e728, 0x32e3, 0x11d6, 0xa6, 0x82, \
				    { 0x7b, 0x03, 0xa0, 0x00, 0x00, 0x00 } }
#define	EFI_RHT_DATA		{ 0x0fc63daf, 0x8483, 0x4772, 0x8e, 0x79, \
				    { 0x3d, 0x69, 0xd8, 0x47, 0x7d, 0xe4 } }
#define	EFI_RHT_HOME		{ 0x933ac7e1, 0x2eb4, 0x4f13, 0xb8, 0x44, \
				    { 0x0e, 0x14, 0xe2, 0xae, 0xf9, 0x15 } }
#define	EFI_RHT_SRV		{ 0x3b8f8425, 0x20e0, 0x4f3b, 0x90, 0x7f, \
				    { 0x1a, 0x25, 0xa7, 0x6f, 0x98, 0xe8 } }
#define	EFI_RHT_DMCRYPT		{ 0x7ffec5c9, 0x2d00, 0x49b7, 0x89, 0x41, \
				    { 0x3e, 0xa1, 0x0a, 0x55, 0x86, 0xb7 } }
#define	EFI_RHT_LUKS		{ 0xca7d7ccb, 0x63ed, 0x4c53, 0x86, 0x1c, \
				    { 0x17, 0x42, 0x53, 0x60, 0x59, 0xcc } }
#define	EFI_FREEBSD_DISKLABEL	{ 0x516e7cb4, 0x6ecf, 0x11d6, 0x8f, 0xf8, \
				    { 0x00, 0x02, 0x2d, 0x09, 0x71, 0x2b } }
#define	EFI_AAPL_RAID		{ 0x52414944, 0x0000, 0x11aa, 0xaa, 0x11, \
				    { 0x00, 0x30, 0x65, 0x43, 0xec, 0xac } }
#define	EFI_AAPL_RAIDOFFLINE	{ 0x52414944, 0x5f4f, 0x11aa, 0xaa, 0x11, \
				    { 0x00, 0x30, 0x65, 0x43, 0xec, 0xac } }
#define	EFI_AAPL_BOOT		{ 0x426f6f74, 0x0000, 0x11aa, 0xaa, 0x11, \
				    { 0x00, 0x30, 0x65, 0x43, 0xec, 0xac } }
#define	EFI_AAPL_LABEL		{ 0x4c616265, 0x6c00, 0x11aa, 0xaa, 0x11, \
				    { 0x00, 0x30, 0x65, 0x43, 0xec, 0xac } }
#define	EFI_AAPL_TVRECOVERY	{ 0x5265636f, 0x7665, 0x11aa, 0xaa, 0x11, \
				    { 0x00, 0x30, 0x65, 0x43, 0xec, 0xac } }
#define	EFI_AAPL_CORESTORAGE	{ 0x53746f72, 0x6167, 0x11aa, 0xaa, 0x11, \
				    { 0x00, 0x30, 0x65, 0x43, 0xec, 0xac } }
#define	EFI_NETBSD_SWAP		{ 0x49f48d32, 0xb10e, 0x11dc, 0xb9, 0x9b, \
				    { 0x00, 0x19, 0xd1, 0x87, 0x96, 0x48 } }
#define	EFI_NETBSD_FFS		{ 0x49f48d5a, 0xb10e, 0x11dc, 0xb9, 0x9b, \
				    { 0x00, 0x19, 0xd1, 0x87, 0x96, 0x48 } }
#define	EFI_NETBSD_LFS		{ 0x49f48d82, 0xb10e, 0x11dc, 0xb9, 0x9b, \
				    { 0x00, 0x19, 0xd1, 0x87, 0x96, 0x48 } }
#define	EFI_NETBSD_RAID		{ 0x49f48daa, 0xb10e, 0x11dc, 0xb9, 0x9b, \
				    { 0x00, 0x19, 0xd1, 0x87, 0x96, 0x48 } }
#define	EFI_NETBSD_CAT		{ 0x2db519c4, 0xb10f, 0x11dc, 0xb9, 0x9b, \
				    { 0x00, 0x19, 0xd1, 0x87, 0x96, 0x48 } }
#define	EFI_NETBSD_CRYPT	{ 0x2db519ec, 0xb10f, 0x11dc, 0xb9, 0x9b, \
				    { 0x00, 0x19, 0xd1, 0x87, 0x96, 0x48 } }
#define	EFI_GOOG_KERN		{ 0xfe3a2a5d, 0x4f32, 0x41a7, 0xb7, 0x25, \
				    { 0xac, 0xcc, 0x32, 0x85, 0xa3, 0x09 } }
#define	EFI_GOOG_ROOT		{ 0x3cb8e202, 0x3b7e, 0x47dd, 0x8a, 0x3c, \
				    { 0x7f, 0xf2, 0xa1, 0x3c, 0xfc, 0xec } }
#define	EFI_GOOG_RESV		{ 0x2e0a753d, 0x9e48, 0x43b0, 0x83, 0x37, \
				    { 0xb1, 0x51, 0x92, 0xcb, 0x1b, 0x5e } }
#define	EFI_HAIKU_BFS		{ 0x42465331, 0x3ba3, 0x10f1, 0x80, 0x2a, \
				    { 0x48, 0x61, 0x69, 0x6b, 0x75, 0x21 } }
#define	EFI_MIDNIGHTBSD_BOOT	{ 0x85d5e45e, 0x237c, 0x11e1, 0xb4, 0xb3, \
				    { 0xe8, 0x9a, 0x8f, 0x7f, 0xc3, 0xa7 } }
#define	EFI_MIDNIGHTBSD_DATA	{ 0x85d5e45a, 0x237c, 0x11e1, 0xb4, 0xb3, \
				    { 0xe8, 0x9a, 0x8f, 0x7f, 0xc3, 0xa7 } }
#define	EFI_MIDNIGHTBSD_SWAP	{ 0x85d5e45b, 0x237c, 0x11e1, 0xb4, 0xb3, \
				    { 0xe8, 0x9a, 0x8f, 0x7f, 0xc3, 0xa7 } }
#define	EFI_MIDNIGHTBSD_UFS	{ 0x0394ef8b, 0x237e, 0x11e1, 0xb4, 0xb3, \
				    { 0xe8, 0x9a, 0x8f, 0x7f, 0xc3, 0xa7 } }
#define	EFI_MIDNIGHTBSD_VINUM	{ 0x85d5e45c, 0x237c, 0x11e1, 0xb4, 0xb3, \
				    { 0xe8, 0x9a, 0x8f, 0x7f, 0xc3, 0xa7 } }
#define	EFI_MIDNIGHTBSD_ZFS	{ 0x85d5e45d, 0x237c, 0x11e1, 0xb4, 0xb3, \
				    { 0xe8, 0x9a, 0x8f, 0x7f, 0xc3, 0xa7 } }
#define	EFI_CEPH_JOURNAL	{ 0x45b0969e, 0x9b03, 0x4f30, 0xb4, 0xc6, \
				    { 0xb4, 0xb8, 0x0c, 0xef, 0xf1, 0x06 } }
#define	EFI_CEPH_DMCRYPTJOURNAL	{ 0x45b0969e, 0x9b03, 0x4f30, 0xb4, 0xc6, \
				    { 0x5e, 0xc0, 0x0c, 0xef, 0xf1, 0x06 } }
#define	EFI_CEPH_OSD		{ 0x4fbd7e29, 0x9d25, 0x41b8, 0xaf, 0xd0, \
				    { 0x06, 0x2c, 0x0c, 0xef, 0xf0, 0x5d } }
#define	EFI_CEPH_DMCRYPTOSD	{ 0x4fbd7e29, 0x9d25, 0x41b8, 0xaf, 0xd0, \
				    { 0x5e, 0xc0, 0x0c, 0xef, 0xf0, 0x5d } }
#define	EFI_CEPH_CREATE		{ 0x89c57f98, 0x2fe5, 0x4dc0, 0x89, 0xc1, \
				    { 0xf3, 0xad, 0x0c, 0xef, 0xf2, 0xbe } }
#define	EFI_CEPH_DMCRYPTCREATE	{ 0x89c57f98, 0x2fe5, 0x4dc0, 0x89, 0xc1, \
				    { 0x5e, 0xc0, 0x0c, 0xef, 0xf2, 0xbe } }
#define	EFI_OPENBSD_DISKLABEL	{ 0x824cc7a0, 0x36a8, 0x11e3, 0x89, 0x0a, \
				    { 0x95, 0x25, 0x19, 0xad, 0x3f, 0x61 } }
#define	EFI_BBRY_QNX		{ 0xcef5a9ad, 0x73bc, 0x4601, 0x89, 0xf3, \
				    { 0xcd, 0xee, 0xee, 0xe3, 0x21, 0xa1 } }
#define	EFI_BELL_PLAN9		{ 0xc91818f9, 0x8025, 0x47af, 0x89, 0xd2, \
				    { 0xf0, 0x30, 0xd7, 0x00, 0x0c, 0x2c } }
#define	EFI_VMW_KCORE		{ 0x9d275380, 0x40ad, 0x11db, 0xbf, 0x97, \
				    { 0x00, 0x0c, 0x29, 0x11, 0xd1, 0xb8 } }
#define	EFI_VMW_VMFS		{ 0xaa31e02a, 0x400f, 0x11db, 0x95, 0x90, \
				    { 0x00, 0x0c, 0x29, 0x11, 0xd1, 0xb8 } }
#define	EFI_VMW_RESV		{ 0x9198effc, 0x31c0, 0x11db, 0x8f, 0x78, \
				    { 0x00, 0x0c, 0x29, 0x11, 0xd1, 0xb8 } }

/* From GPT fdisk */

#define	EFI_RHT_ROOTX86		{ 0x44479540, 0xf297, 0x41b2, 0x9a, 0xf7, \
				    { 0xd1, 0x31, 0xd5, 0xf0, 0x45, 0x8a } }
#define	EFI_RHT_ROOTAMD64	{ 0x4f68bce3, 0xe8cd, 0x4db1, 0x96, 0xe7, \
				    { 0xfb, 0xca, 0xf9, 0x84, 0xb7, 0x09 } }
#define	EFI_RHT_ROOTARM		{ 0x69dad710, 0x2ce4, 0x4e3c, 0xb1, 0x6c, \
				    { 0x21, 0xa1, 0xd4, 0x9a, 0xbe, 0xd3 } }
#define	EFI_RHT_ROOTARM64	{ 0xb921b045, 0x1df0, 0x41c3, 0xaf, 0x44, \
				    { 0x4c, 0x6f, 0x28, 0x0d, 0x3f, 0xae } }
#define	EFI_ACRONIS_SECUREZONE	{ 0x0311fc50, 0x01ca, 0x4725, 0xad, 0x77, \
				    { 0x9a, 0xdb, 0xb2, 0x0a, 0xce, 0x98 } }
#define	EFI_ONIE_BOOT		{ 0x7412f7d5, 0xa156, 0x4b13, 0x81, 0xdc, \
				    { 0x86, 0x71, 0x74, 0x92, 0x93, 0x25 } }
#define	EFI_ONIE_CONFIG		{ 0xd4e6e2cd, 0x4469, 0x46f3, 0xb5, 0xcb, \
				    { 0x1b, 0xff, 0x57, 0xaf, 0xc1, 0x49 } }
#define	EFI_IBM_PPRPBOOT	{ 0x9e1a2d38, 0xc612, 0x4316, 0xaa, 0x26, \
				    { 0x8b, 0x49, 0x52, 0x1e, 0x5a, 0x8b } }
#define	EFI_FREEDESKTOP_BOOT	{ 0xbc13c2ff, 0x59e6, 0x4262, 0xa3, 0x52, \
				    { 0xb2, 0x75, 0xfd, 0x6f, 0x71, 0x72 } }

/* minimum # of bytes for partition table entries, per EFI spec */
#define	EFI_MIN_ARRAY_SIZE	(16 * 1024)

#define	EFI_PART_NAME_LEN	36

/* size of the "reserved" partition, in blocks */
#define	EFI_MIN_RESV_SIZE	(16 * 1024)

/* EFI Guid Partition Entry */
typedef struct efi_gpe {
	struct uuid	efi_gpe_PartitionTypeGUID;
	struct uuid	efi_gpe_UniquePartitionGUID;
	diskaddr_t	efi_gpe_StartingLBA;
	diskaddr_t	efi_gpe_EndingLBA;
	efi_gpe_Attrs_t	efi_gpe_Attributes;
	ushort_t	efi_gpe_PartitionName[EFI_PART_NAME_LEN];
} efi_gpe_t;

/*
 * passed to the useful (we hope) routines (efi_alloc_and_read and
 * efi_write) that take this VTOC-like struct.  These routines handle
 * converting this struct into the EFI struct, generate UUIDs and
 * checksums, and perform any necessary byte-swapping to the on-disk
 * format.
 */
/* Solaris library abstraction for EFI partitions */
typedef struct dk_part	{
	diskaddr_t	p_start;	/* starting LBA */
	diskaddr_t	p_size;		/* size in blocks */
	struct uuid	p_guid;		/* partition type GUID */
	ushort_t	p_tag;		/* converted to part'n type GUID */
	ushort_t	p_flag;		/* attributes */
	char		p_name[EFI_PART_NAME_LEN]; /* partition name */
	struct uuid	p_uguid;	/* unique partition GUID */
	uint_t		p_resv[8];	/* future use - set to zero */
} dk_part_t;

/* Solaris library abstraction for an EFI GPT */
#define	EFI_VERSION102		0x00010002
#define	EFI_VERSION100		0x00010000
#define	EFI_VERSION_CURRENT	EFI_VERSION100
typedef struct dk_gpt {
	uint_t		efi_version;	/* set to EFI_VERSION_CURRENT */
	uint_t		efi_nparts;	/* number of partitions below */
	uint_t		efi_part_size;	/* size of each partition entry */
					/* efi_part_size is unused */
	uint_t		efi_lbasize;	/* size of block in bytes */
	diskaddr_t	efi_last_lba;	/* last block on the disk */
	diskaddr_t	efi_first_u_lba; /* first block after labels */
	diskaddr_t	efi_last_u_lba;	/* last block before backup labels */
	struct uuid	efi_disk_uguid;	/* unique disk GUID */
	uint_t		efi_flags;
	uint_t		efi_reserved1;	/* future use - set to zero */
	diskaddr_t	efi_altern_lba;	/* lba of alternate GPT header */
	uint_t		efi_reserved[12]; /* future use - set to zero */
	struct dk_part	efi_parts[1];	/* array of partitions */
} dk_gpt_t;

/* possible values for "efi_flags" */
#define	EFI_GPT_PRIMARY_CORRUPT	0x1	/* primary label corrupt */

/* the private ioctl between libefi and the driver */
typedef struct dk_efi {
	diskaddr_t	 dki_lba;	/* starting block */
	len_t		 dki_length;	/* length in bytes */
	union {
		efi_gpt_t 	*_dki_data;
		uint64_t	_dki_data_64;
	} dki_un;
#define	dki_data	dki_un._dki_data
#define	dki_data_64	dki_un._dki_data_64
} dk_efi_t;

struct partition64 {
	struct uuid	p_type;
	uint_t		p_partno;
	uint_t		p_resv1;
	diskaddr_t	p_start;
	diskaddr_t	p_size;
};

/*
 * Number of EFI partitions
 */
#if defined(__linux__)
#define	EFI_NUMPAR	128 /* Expected by parted-1.8.1 */
#else
#define	EFI_NUMPAR	9
#endif

#ifndef _KERNEL
#define	VT_ERROR	(-2)		/* errno supplies specific error */
#define	VT_EIO		(-3)		/* I/O error accessing vtoc */
#define	VT_EINVAL	(-4)		/* illegal value in vtoc or request */
#define	VT_ENOSPC	(-6)		/* requested space not found */

_SYS_EFI_PARTITION_H int efi_debug;
_SYS_EFI_PARTITION_H int efi_alloc_and_init(int, uint32_t, struct dk_gpt **);
_SYS_EFI_PARTITION_H int efi_alloc_and_read(int, struct dk_gpt **);
_SYS_EFI_PARTITION_H int efi_write(int, struct dk_gpt *);
_SYS_EFI_PARTITION_H int efi_rescan(int);
_SYS_EFI_PARTITION_H void efi_free(struct dk_gpt *);
_SYS_EFI_PARTITION_H void efi_err_check(struct dk_gpt *);
_SYS_EFI_PARTITION_H int efi_use_whole_disk(int fd);
#endif

#ifdef __cplusplus
}
#endif

#endif /* _SYS_EFI_PARTITION_H */
