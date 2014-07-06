#!/bin/bash

# switch to basic language
export LANG=C
export LC_MESSAGES=C

CHROOT=/opt/manjarobuild
ARCH=$(uname -m)
BRANCH=unstable
USER=$(ls ${CHROOT}/${BRANCH}-${ARCH} | cut -d' ' -f1 | grep -v root | grep -v lock)

# do UID checking here so someone can at least get usage instructions
if [ "$EUID" != "0" ]; then
    echo "error: This script must be run as root."
    exit 1
fi

# Get host mirror
host_mirror=$(pacman -Sddp extra/devtools 2>/dev/null | sed -E "s#(.*/)(.*/)extra/.*#\1${branch}/\$repo/\$arch#")
if echo "${host_mirror}" | grep -q 'file://'; then
	host_mirror_path=$(echo "${host_mirror}" | sed -E 's#file://(/.*)/\$repo/\$arch#\1#g')
fi

${BRANCH}-${ARCH}-build -c -r ${CHROOT}

echo "==> Fixing branch in chroot"
echo "Server = ${host_mirror}" > ${CHROOT}/${BRANCH}-${ARCH}/root/etc/pacman.d/mirrorlist
sed -i -e "s|^.*Branch=.*|Branch=${BRANCH}|" ${CHROOT}/${BRANCH}-${ARCH}/root/etc/pacman-mirrors.conf
pacman -Syy -r ${CHROOT}/${BRANCH}-${ARCH}/root
#pacman -Syy -r ${CHROOT}/${BRANCH}-${ARCH}/$USER
echo "==> Done fixing branch in chroot"

echo "==> Start building sugar"
date
for pkg in $(cat build-order); do cd $pkg && makechrootpkg -n -r ${CHROOT}/${BRANCH}-${ARCH} || break && cd ..; done
date
echo "==> Done building sugar"
#shutdown -h now
