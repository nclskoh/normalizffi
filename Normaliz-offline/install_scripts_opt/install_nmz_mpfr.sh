#!/usr/bin/env bash

set -e

echo "::group::mpfr"

source $(dirname "$0")/common.sh

source $(dirname "$0")/common.sh

CONFIGURE_FLAGS="--prefix=${PREFIX}"
if [ "$GMP_INSTALLDIR" != "" ]; then
    CONFIGURE_FLAGS="${CONFIGURE_FLAGS} --with-gmp=$GMP_INSTALLDIR"
fi

echo "MPFR flags"
echo $CONFIGURE_FLAGS

## script for the installation of MPFR (needed for Flint)

MPFR_VERSION="4.1.0"
MPFR_URL="https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFR_VERSION}.tar.gz"
MPFR_SHA256=3127fe813218f3a1f0adf4e8899de23df33b4cf4b4b3831a5314f78e65ffa2d6

echo "Installing MPFR..."

# download & extract
mkdir -p ${NMZ_OPT_DIR}/MPFR_source/
cd ${NMZ_OPT_DIR}/MPFR_source

#../../download.sh ${MPFR_URL} ${MPFR_SHA256}
cp ${DOWNLOAD_DIR}/${MPFR_PACKAGE} ./

if [ ! -d mpfr-${MPFR_VERSION} ]; then
    tar -xvf ${MPFR_PACKAGE}
fi

# configure & compile
cd mpfr-${MPFR_VERSION}
if [ ! -f config.status ]; then
    echo "Vor mpdfr configure"
    echo $CONFIGURE_FLAGS
    ./configure ${CONFIGURE_FLAGS}
fi

make -j2
make install

echo "MPFR installed"
