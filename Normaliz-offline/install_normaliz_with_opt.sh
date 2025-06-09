#!/usr/bin/env bash

set -e

# Remove cocoa and nauty; normaliz still needs Flint.
./install_scripts_opt/install_nmz_mpfr.sh
./install_scripts_opt/install_nmz_flint.sh
./install_normaliz.sh
