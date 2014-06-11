# Adapted from: distrib/amd64/common/Makefile.inc:
#       $OpenBSD: Makefile.inc,v 1.25 2014/03/02 15:57:34 deraadt Exp $
#   and yaifo/Makefile:
#       https://github.com/shtrom/yaifo/blob/master/Makefile
#   and flashboot/Makefile:
#       https://github.com/openbsd/flashboot/blob/master/Makefile

.if !defined(SRCDIR)
SRCDIR=/usr/src
.endif
P!=pwd
TOP=${P}/..

REV=            55
RAMDISK=        RAMDISK_CD
IMAGE=          mr.fs
CBIN?=          instbin
CRUNCHCONF?=    ${CBIN}.conf
LISTS?=         ${SRCDIR}/distrib/amd64/common/list
UTILS?=         ${SRCDIR}/distrib/miniroot

MOUNT_POINT=    /mnt
MTREE=          ${UTILS}/mtree.conf

XNAME?=         floppy
FS?=            ${XNAME}${REV}.fs
VND?=           vnd0
VND_DEV=        /dev/${VND}a
VND_RDEV=       /dev/r${VND}a
VND_CRDEV=      /dev/r${VND}c
PID!=           echo $$$$
REALIMAGE!=     echo /var/tmp/image.${PID}
BOOT?=          ${DESTDIR}/usr/mdec/boot
FLOPPYSIZE?=    98304
FLOPPYTYPE?=    floppy3

all:    ${FS}

${FS}:  bsd.gz
	dd if=/dev/zero of=${REALIMAGE} bs=512 count=${FLOPPYSIZE}
	vnconfig -v -c ${VND} ${REALIMAGE}
	.ifdef LBA
	fdisk -yi -l ${FLOPPYSIZE} -f ${DESTDIR}/usr/mdec/mbr ${VND}
	.endif
	disklabel -w ${VND} ${FLOPPYTYPE}
	newfs -m 0 -o space -i 524288 -c ${FLOPPYSIZE} ${VND_RDEV}
	mount ${VND_DEV} ${MOUNT_POINT}
	cp ${BOOT} ${.OBJDIR}/boot
	strip ${.OBJDIR}/boot
	strip -R .comment ${.OBJDIR}/boot
	dd if=bsd.gz of=${MOUNT_POINT}/bsd bs=512
	installboot -v -r ${MOUNT_POINT} ${VND_CRDEV} \
		${DESTDIR}/usr/mdec/biosboot ${.OBJDIR}/boot
	@echo ""
	@df -i ${MOUNT_POINT}
	@echo ""
	umount ${MOUNT_POINT}
	vnconfig -u ${VND}
	cp ${REALIMAGE} ${FS}
	rm ${REALIMAGE}

DISKTYPE?=       rdroot
NBLKS?=          196608

# minfree, opt, b/i  trks, sects, cpg
NEWFSARGS= -m 0 -o space -i 8192

bsd.gz: bsd.rd
	cp bsd.rd bsd.strip
	strip bsd.strip
	strip -R .comment bsd.strip
	gzip -c9n bsd.strip > bsd.gz

bsd.rd: ${IMAGE} bsd rdsetroot
	cp bsd bsd.rd
	${.OBJDIR}/rdsetroot bsd.rd ${IMAGE}

bsd:
	cd ${SRCDIR}/sys/arch/amd64/conf && config ${RAMDISK}
	cd ${SRCDIR}/sys/arch/amd64/compile/${RAMDISK} && \
		${MAKE} clean && COPTS=-Os exec ${MAKE}
	cp ${SRCDIR}/sys/arch/amd64/compile/${RAMDISK}/bsd bsd

${IMAGE}: ${CBIN} rd_setup do_files rd_teardown

rd_setup: ${CBIN}
	dd if=/dev/zero of=${REALIMAGE} bs=512 count=${NBLKS}
	vnconfig -v -c ${VND} ${REALIMAGE}
	disklabel -w ${VND} ${DISKTYPE}
	newfs ${NEWFSARGS} ${VND_RDEV}
	fsck ${VND_RDEV}
	mount ${VND_DEV} ${MOUNT_POINT}

rd_teardown:
	@df -i ${MOUNT_POINT}
	-umount ${MOUNT_POINT}
	-vnconfig -u ${VND}
	cp ${REALIMAGE} ${IMAGE}
	rm ${REALIMAGE}

rdsetroot:      ${SRCDIR}/distrib/common/elfrdsetroot.c
	${HOSTCC} ${HOSTCFLAGS} -o rdsetroot \
		${SRCDIR}/distrib/common/elfrdsetroot.c ${SRCDIR}/distrib/common/elf32.c \
		${SRCDIR}/distrib/common/elf64.c

unconfig:
	-umount -f ${MOUNT_POINT}
	-vnconfig -u ${VND}

.PRECIOUS:      ${IMAGE}

.ifdef RELEASEDIR
install:
	.ifndef NOBSDRD
	cp bsd.rd ${RELEASEDIR}/bsd.rd
	.endif
	.ifndef NOFS
	cp ${FS} ${RELEASEDIR}/${FS}
	.endif
	.endif  # RELEASEDIR

${CBIN}.mk ${CBIN}.cache ${CBIN}.c: ${CRUNCHCONF}
	crunchgen -E -D ${BSDSRCDIR} -L ${DESTDIR}/usr/lib \
		-c ${CBIN}.c -e ${CBIN} -m ${CBIN}.mk ${CRUNCHCONF}

${CBIN}: ${CBIN}.mk ${CBIN}.cache ${CBIN}.c
	${MAKE} -f ${CBIN}.mk SRCLIBDIR=${SRCDIR}/../lib all
	strip -R .comment ${CBIN}

${CRUNCHCONF}: ${LISTS}
	awk -f ${UTILS}/makeconf.awk CBIN=${CBIN} ${LISTS} > ${CRUNCHCONF}

do_files:
	mtree -def ${MTREE} -p ${MOUNT_POINT}/ -u
	TOPDIR=${TOP} CURDIR=${SRCDIR}/distrib/amd64/common OBJDIR=${.OBJDIR} \
			 REV=${REV} TARGDIR=${MOUNT_POINT} UTILS=${UTILS} \
			 RELEASEDIR=${RELEASEDIR} sh ${UTILS}/runlist.sh ${LISTS}
	rm ${MOUNT_POINT}/${CBIN}

clean cleandir:
	/bin/rm -f *.core ${IMAGE} ${CBIN} ${CBIN}.mk ${CBIN}*.cache \
		*.o *.lo *.c bsd bsd.rd bsd.gz bsd.strip floppy*.fs \
		lib*.a lib*.olist ${CBIN}.map \
		rdsetroot boot ${CRUNCHCONF} ${FS}

.include <bsd.obj.mk>
.include <bsd.subdir.mk>
