#!/usr/bin/env bash

# Some common definition used by the various install*sh scripts

if [ "x$NMZ_OPT_DIR" = x ]; then
    export NMZ_OPT_DIR="${PWD}"/nmz_opt_lib
    mkdir -p ${NMZ_OPT_DIR}
fi

if [ "x$NMZ_COMPILER" != x ]; then
    export CXX=$NMZ_COMPILER
elif [[ $OSTYPE == darwin* ]]; then   ## activate Homebrew LLVM
    LLVMDIR="$(brew --prefix)/opt/llvm"
    export LDFLAGS="${LDFLAGS} -L${LLVMDIR}/lib -Wl,-rpath,${LLVMDIR}/lib"
    export CPPFLAGS="${CPPFLAGS} -I ${LLVMDIR}/include"
    export PATH="${LLVMDIR}/bin/:$PATH"
    export CXX=clang++
    export CC=clang
    echo "CLANG++ VERSION"
    clang++ --version
    echo "CLANG VERSION"
    clang --version
fi

if [ "x$NMZ_PREFIX" != x ]; then
    mkdir -p ${NMZ_PREFIX}
    export PREFIX=${NMZ_PREFIX}
else
    export PREFIX=${PWD}/local
fi

if [[ $OSTYPE == darwin* ]] &&  [ "$GMP_INSTALLDIR" == "" ]; then
    GMP_INSTALLDIR=/usr/local
fi

echo "GMP INSTALL DIR is $GMP_INSTALLDIR"

if [ "$GMP_INSTALLDIR" != "" ]; then
    export CPPFLAGS="${CPPFLAGS} -I${GMP_INSTALLDIR}/include"
    export LDFLAGS="${LDFLAGS} -L${GMP_INSTALLDIR}/lib"
fi

# Make sure our library versions come first in the search path
export CPPFLAGS="-I${PREFIX}/include ${CPPFLAGS}"
export LDFLAGS="-L${PREFIX}/lib ${LDFLAGS}"


if [[ $OSTYPE != darwin* ]]; then
    # Since we're installing into a non-standard prefix, we have to help
    # the linker find indirect dependencies such as libantic.so which is a
    # dependency of libeantic.so. (We could also overlink, and link with
    # -lantic but we do not depend on antic directly, so we should not do
    # that; see e.g. http://www.kaizou.org/2015/01/linux-libraries.html.)
    # For some odd reason Debian does not render rpath-link as a RUNPATH in a
    # shared C library, so we set the rpath instead which appears to have the
    # same effect.
    export LDFLAGS="${LDFLAGS} -Wl,-enable-new-dtags -Wl,-rpath=${PREFIX}/lib"
fi

mkdir -p ${PREFIX}/lib
mkdir -p ${PREFIX}/include

COCOA_VERSION="0.99710"
COCOA_URL="http://cocoa.dima.unige.it/cocoalib/tgz/CoCoALib-${COCOA_VERSION}.tgz"
COCOA_SHA256=80d472fd74c7972f8f2a239679e7ad8ae8a43676e3c259c2218ae2480a6267a8

MPFR_VERSION="4.1.0"
MPFR_URL="https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFR_VERSION}.tar.gz"
MPFR_SHA256=3127fe813218f3a1f0adf4e8899de23df33b4cf4b4b3831a5314f78e65ffa2d6

FLINT_VERSION="2.8.0"
FLINT_URL="https://flintlib.org/flint-${FLINT_VERSION}.tar.gz"
FLINT_SHA256=584235cdc39d779d9920eaef16fe084f3c26ffeeea003a3fff64a20a0f33449e

ARB_VERSION="2.20.0"
ARB_URL="https://github.com/fredrik-johansson/arb/archive/${ARB_VERSION}.tar.gz"
ARB_SHA256=d2f186b10590c622c11d1ca190c01c3da08bac9bc04e84cb591534b917faffe7

ANTIC_VERSION=0.2.4
ANTIC_URL="https://github.com/wbhart/antic/archive/v${ANTIC_VERSION}.tar.gz"
ANTIC_SHA256=517d53633ff9c6348549dc6968567051b2161098d2bc395cb40ecc41e24312c6

E_ANTIC_VERSION=1.0.3
E_ANTIC_URL="https://github.com/flatsurf/e-antic/releases/download/${E_ANTIC_VERSION}/e-antic-${E_ANTIC_VERSION}.tar.gz"
E_ANTIC_SHA256=eea1dc66fed5962425bc7d2c5ccecb50d25c082b1d84276fa3838bfa96d9cb62

NAUTY_VERSION="27r2"
# NAUTY_URL="https://pallini.di.uniroma1.it/nauty${NAUTY_VERSION}.tar.gz"
NAUTY_URL="https://users.cecs.anu.edu.au/~bdm/nauty/nauty${NAUTY_VERSION}.tar.gz"
NAUTY_SHA256=fc434729c833d9bb7053c8def10e72eaede03487d1afa50568ce2972b0337741

export DOWNLOAD_DIR="${PWD}"/download
export COCOA_PACKAGE=CoCoALib-${COCOA_VERSION}.tgz
export ANTIC_PACKAGE=antic-v${ANTIC_VERSION}.tar.gz
export ARB_PACKAGE=arb-${ARB_VERSION}.tar.gz
export E_ANTIC_PACKAGE=e-antic-${E_ANTIC_VERSION}.tar.gz
export FLINT_PACKAGE=flint-${FLINT_VERSION}.tar.gz
export MPFR_PACKAGE=mpfr-${MPFR_VERSION}.tar.gz
export NAUTY_PACKAGE=nauty${NAUTY_VERSION}.tar.gz

echo "**************"
echo "common.sh: NMZ_OPT_DIR is: ${NMZ_OPT_DIR}"
echo "common.sh: Installation prefix is: ${PREFIX}"
echo "common.sh: CPPFlags is: ${CPPFLAGS}"
echo "common.sh: LDFLAGS is: ${LDFLAGS}"
echo "common.sh: DOWNLOAD_DIR is: ${DOWNLOAD_DIR}"
echo "-----------"
