#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ASSIGNMENT_REPO_DIR=$(realpath $(dirname $FINDER_APP_DIR))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
    mv linux/ linux-stable
fi

if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # Add your kernel build steps here

    # QEMU deep clean the kernel build tree removing .config file with any existing configurations
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper

    # configure for our "virt" arm dev board we will simulate in QEMU
    make ARCH=${ARCH}  CROSS_COMPILE=${CROSS_COMPILE} defconfig

    # Now Build a kernel image for booting with QEMU. Use multi core for speed.
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all

    # build any kernel modules
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules

    # build the devicetree
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

cd ${OUTDIR}/linux-stable
echo "Adding the Image in outdir"
cp arch/arm64/boot/Image ${OUTDIR}


echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories: Necessary as rootfs/bin will be used by busybox
mkdir -p ${OUTDIR}/rootfs && cd ${OUTDIR}/rootfs
mkdir -p bin etc dev home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin 
mkdir -p var/log 

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone https://git.busybox.net/busybox
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make distclean
    make defconfig
else
    cd busybox
fi

# TODO: Make and install busybox
# make
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
# install
make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

cd "$OUTDIR/rootfs"
echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
# found program interpreter in cross compiler sysroot: 
# /home/olatuyi/arm-cross-compiler/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc/lib
# found shared lib in 
# /home/olatuyi/arm-cross-compiler/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc/lib64
# manually moved dependencies into repo root 
cp -r ${ASSIGNMENT_REPO_DIR}/Arm64_Lib_Dependencies/lib64/* ${OUTDIR}/rootfs/lib64
cp -r ${ASSIGNMENT_REPO_DIR}/Arm64_Lib_Dependencies/lib/* ${OUTDIR}/rootfs/lib

# TODO: Make device nodes with character type
# null device

# make null device if it doesn't exist
# if [ ! -e dev/null ]; then
#     if [ ! -e "./dev" ] && [ ! -d "./dev" ]; then
#         echo "Making dev directory in rootfs"
#         mkdir ./dev
#     fi
#     sudo mknod -m 666 dev/null c 1 3
# fi
# # make console device if it doesn't exist
# if [ ! -e dev/console ]; then
#     sudo mknod -m 666 dev/console c 5 1
# fi
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 666 dev/console c 5 1


# TODO: Clean and build the writer utility
cd ${FINDER_APP_DIR}
make CROSS_COMPILE=${CROSS_COMPILE} clean
make CROSS_COMPILE=${CROSS_COMPILE} all

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs start-qemu-terminal script: ref kernel image and rootfs
if [ ! -d ${OUTDIR}/rootfs/home/conf ]; then
    echo "Making home directory in rootfs/home/conf"
    mkdir -p ${OUTDIR}/rootfs/home/conf
fi
cp ${FINDER_APP_DIR}/*.sh ${OUTDIR}/rootfs/home
cp ${FINDER_APP_DIR}/writer ${OUTDIR}/rootfs/home/writer

#
cp ${ASSIGNMENT_REPO_DIR}/conf/username.txt ${OUTDIR}/rootfs/home/conf/username.txt
cp ${ASSIGNMENT_REPO_DIR}/conf/assignment.txt ${OUTDIR}/rootfs/home/conf/assignment.txt

cd "$OUTDIR"

# TODO: Chown the root directory
sudo chown -R root:root ${OUTDIR}/rootfs

# TODO: Create initramfs.cpio.gz
cd ${OUTDIR}/rootfs
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
gzip -f  ${OUTDIR}/initramfs.cpio
