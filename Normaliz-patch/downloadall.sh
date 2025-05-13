#!/usr/bin/env bash

# overload on common.sh to get software URLs and SHAs
source ./install_scripts_opt/common.sh

# ./download.sh ${COCOA_URL} ${COCOA_SHA256}
./download.sh ${MPFR_URL} ${MPFR_SHA256}
./download.sh ${FLINT_URL} ${FLINT_SHA256}
# ./download.sh ${E_ANTIC_URL} ${E_ANTIC_SHA256}
./download.sh ${NAUTY_URL} ${NAUTY_SHA256}

mv *.tar.gz download/
mv *.tar.xz download/
