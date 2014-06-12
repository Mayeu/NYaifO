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
RAMDISK=        RAMDISK_NYAIFO
XNAME=          nyaifo
IMAGE=          mr.fs
CBIN?=          instbin
CRUNCHCONF?=    ${CBIN}.conf
LISTS?=         ${SRCDIR}/distrib/amd64/common/list
UTILS?=         ${SRCDIR}/distrib/miniroot

MOUNT_POINT=    /mnt
MTREE=          ${UTILS}/mtree.conf

FS?=            ${XNAME}.fs
VND?=           vnd0
VND_DEV=        /dev/${VND}a
VND_RDEV=       /dev/r${VND}a
VND_CRDEV=      /dev/r${VND}c
PID!=           echo $$$$
REALIMAGE!=     echo /var/tmp/image.${PID}
BOOT?=          ${DESTDIR}/usr/mdec/boot

OBJCOPY=	objcopy -Sg -R .comment
IMAGESIZE=      16384
RDSIZE=		8192
NEWFSARGS=      -m 0 -o space -i 8192

all:    ${FS}

${FS}:  bsd.gz
	dd if=/dev/zero of=${REALIMAGE} bs=512 count=${IMAGESIZE}
	vnconfig -v -c ${VND} ${REALIMAGE}
	fdisk -yi ${VND}
	printf "a a\n\n\n\nw\nq\n" | disklabel -E ${VND} > /dev/null 2>&1
	newfs ${NEWFSARGS} -c ${IMAGESIZE} ${VND_RDEV}
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

bsd.gz: bsd.rd
	${OBJCOPY} bsd.rd bsd.strip
	strip bsd.strip
	strip -R .comment bsd.strip
	gzip -c9n bsd.strip > bsd.gz

bsd.rd: ${IMAGE} bsd rdsetroot
	cp bsd bsd.rd
	${.OBJDIR}/rdsetroot bsd.rd ${IMAGE}

bsd:
	#cd ${SRCDIR}/sys/arch/amd64 && config ${RAMDISK}
	#cd ${SRCDIR}/sys/arch/amd64/compile/${RAMDISK} && \
	#	${MAKE} clean && COPTS=-Os exec ${MAKE}
	#cp ${SRCDIR}/sys/arch/amd64/compile/${RAMDISK}/bsd bsd
	mkdir -p ${.OBJDIR}/kernel
	config -b ${.OBJDIR}/kernel -s ${SRCDIR}/sys ${.CURDIR}/amd64/${RAMDISK}
	cd ${.OBJDIR}/kernel && \
		make clean && make depend && COPTS=-Os make
	cp ${.OBJDIR}/kernel/bsd bsd

${IMAGE}: ${CBIN} rd_setup do_files rd_teardown

rd_setup: ${CBIN}
	dd if=/dev/zero of=${REALIMAGE} bs=512 count=${RDSIZE}
	vnconfig -v -c ${VND} ${REALIMAGE}
	fdisk -iy ${VND_CRDEV}
	printf "a a\n\n\n\nw\nq\n" | disklabel -E ${VND} > /dev/null 2>&1
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
