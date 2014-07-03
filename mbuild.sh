#!/bin/bash

# switch to basic language
export LANG=C
export LC_MESSAGES=C

CHROOT=/opt/manjarobuild
ARCH=$(uname -m)
BRANCH=unstable

# do UID checking here so someone can at least get usage instructions
if [ "$EUID" != "0" ]; then
    echo "error: This script must be run as root."
    exit 1
fi

${BRANCH}-${ARCH}-build -c -r ${CHROOT}

echo "==> Start building sugar"
date
for pkg in $(cat build-order); do cd $pkg && makechrootpkg -n -r ${CHROOT}/${BRANCH}-${ARCH} || break && cd ..; done
date
echo "==> Done building sugar"
#shutdown -h now
