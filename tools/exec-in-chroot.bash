#!/bin/bash

_program="eic"
_chrootIdentifier="chrooted"


if [[ "$2" != "" ]]; then

	_chrootDir="$1"
	_script="$2"
else
	echo "Usage: ${_program} <CHROOT_DIR> <SCRIPT>"
	exit 64
fi

echo -n "${_program}: Mounting pseudo file systems into chroot environment... "

mount -t proc proc ${_chrootDir}/proc && \
mount -t sysfs sysfs ${_chrootDir}/sys && \
mount -t devtmpfs udev ${_chrootDir}/dev && \
mount -t devpts devpts ${_chrootDir}/dev/pts && \
mount -t tmpfs tmpfs ${_chrootDir}/tmp

if [[ $? -ne 0 ]]; then

	echo -e "\n${_program}: Errors during mount operations. Exiting."
	exit 1
else
	echo "OK"
fi

echo "${_program}: Entering chroot environment..."

chroot $1 env -i "$_script"

echo "${_program}: Exited chroot environment."

echo -n "${_program}: Unmounting pseudo file systems... "

# unmount pseudo file systems
umount ${_chrootDir}/tmp \
       ${_chrootDir}/dev/pts

if ! umount ${_chrootDir}/dev; then

	sleep 5
	umount ${_chrootDir}/dev
fi

umount ${_chrootDir}/sys \
       ${_chrootDir}/proc

if [[ $? -ne 0 ]]; then

        echo -e "\n${_program}: Errors during umount operations. Exiting."
        exit 1
else
        echo "OK"
fi

exit
