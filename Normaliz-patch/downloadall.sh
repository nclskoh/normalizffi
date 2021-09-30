#!/usr/bin/env bash

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

./download.sh ${MPFR_URL} ${MPFR_SHA256}
./download.sh ${FLINT_URL} ${FLINT_SHA256}
./download.sh ${ARB_URL} ${ARB_SHA256}
./download.sh ${ANTIC_URL} ${ANTIC_SHA256}
./download.sh ${E_ANTIC_URL} ${E_ANTIC_SHA256}
