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

if [ "$OSTYPE" == "msys" ]; then
	export MSYS_STANDARD_LOC=/mingw64
fi

if [ "x$NMZ_PREFIX" != x ]; then
    mkdir -p ${NMZ_PREFIX}
    export PREFIX=${NMZ_PREFIX}
else
    export PREFIX=${PWD}/local
fi

if [[ $OSTYPE == darwin* ]] &&  [ "$GMP_INSTALLDIR" == "" ]; then
    GMP_INSTALLDIR=$(brew --prefix)
fi

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
	#
	# --enable-new-dtags not allowed for MSYS, likewise -rpath not allowed for gcc
	if [ "$OSTYPE" != "msys" ]; then
		export LDFLAGS="${LDFLAGS} -Wl,--enable-new-dtags -Wl,-rpath=${PREFIX}/lib"
	fi
fi

mkdir -p ${PREFIX}/lib
mkdir -p ${PREFIX}/include

MPFR_VERSION="4.2.1"
MPFR_URL="https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFR_VERSION}.tar.xz"
MPFR_SHA256=277807353a6726978996945af13e52829e3abd7a9a5b7fb2793894e18f1fcbb

FLINT_VERSION="3.0.1"
# NK: Outdated URL: FLINT_URL="https://flintlib.org/flint-${FLINT_VERSION}.tar.gz"
FLINT_URL="https://flintlib.org/download/flint-${FLINT_VERSION}.tar.gz"
FLINT_SHA256=7b311a00503a863881eb8177dbeb84322f29399f3d7d72f3b1a4c9ba1d5794b4

NAUTY_VERSION="2_8_8"
# NAUTY_URL="https://pallini.di.uniroma1.it/nauty${NAUTY_VERSION}.tar.gz"
NAUTY_URL="https://users.cecs.anu.edu.au/~bdm/nauty/nauty${NAUTY_VERSION}.tar.gz"
NAUTY_SHA256=159d2156810a6bb240410cd61eb641add85088d9f15c888cdaa37b8681f929ce

COCOA_VERSION="0.99818"
COCOA_URL="https://github.com/Normaliz/Normaliz/releases/download/v3.10.3/CoCoALib-0.99818.tgz"
COCOA_SHA256=7c7d6bb0bc3004ea76caaeb5f8de10ed09c8052a9131fd98716c36c6fc96d1ea

E_ANTIC_VERSION=2.0.2
E_ANTIC_URL="https://github.com/flatsurf/e-antic/releases/download/${E_ANTIC_VERSION}/e-antic-${E_ANTIC_VERSION}.tar.gz"
E_ANTIC_SHA256=8328e6490129dfec7f4aa478ebd54dc07686bd5e5e7f5f30dcf20c0f11b67f60

export DOWNLOAD_DIR="${PWD}"/download
export FLINT_PACKAGE=flint-${FLINT_VERSION}.tar.gz
export MPFR_PACKAGE=mpfr-${MPFR_VERSION}.tar.xz
export NAUTY_PACKAGE=nauty${NAUTY_VERSION}.tar.gz

echo "**************"
echo "common.sh: NMZ_OPT DIR is: ${NMZ_OPT_DIR}"
echo "common.sh: Installation prefix is: ${PREFIX}"
echo "common.sh: CPPFLAGS is ${CPPFLAGS}"
echo "common.sh: LDFLAGS is ${LDFLAGS}"
echo "common.sh: DOWNLOAD_DIR is: ${DOWNLOAD_DIR}"
echo "-----------"
