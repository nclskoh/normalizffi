#!/usr/bin/env bash

set -e

echo "::group::mpfr"

source $(dirname "$0")/common.sh

# NK: Make PIC
CONFIGURE_FLAGS="--prefix=${PREFIX} --enable-shared=yes --with-pic=yes"

if [ "$OSTYPE" != "msys" ]; then
	CONFIGURE_FLAGS="${CONFIGURE_FLAGS} --with-mpfr=${PREFIX}"
else # only static here, we take shared from MSYS repository
	CONFIGURE_FLAGS="${CONFIGURE_FLAGS} --with-gmp=${MSYS_STANDARD_LOC} --disable-shared"
fi

if [ "$GMP_INSTALLDIR" != "" ]; then
    CONFIGURE_FLAGS="${CONFIGURE_FLAGS} --with-gmp=$GMP_INSTALLDIR"
fi


echo "MPFR flags"
echo $CONFIGURE_FLAGS

## script for the installation of MPFR (needed for Flint)

MPFR_VERSION="4.2.1"
MPFR_URL="https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFR_VERSION}.tar.xz"
MPFR_SHA256=277807353a6726978996945af13e52829e3abd7a9a5b7fb2793894e18f1fcbb2

# NK: Simplified nmz_opt directory and make it permanent.
echo "Installing MPFR 4.2.1..."

cd ${NMZ_OPT_DIR}
if [ ! -d mpfr-${MPFR_VERSION} ]; then
    tar -xvf mpfr-${MPFR_VERSION}.tar.xz
fi

# configure & compile
cd mpfr-${MPFR_VERSION}
if [ ! -f config.status ]; then
    echo "Vor mpfr configure"
    echo $CONFIGURE_FLAGS
    ./configure ${CONFIGURE_FLAGS}
fi

make -j4
make install

echo "MPFR installed"
