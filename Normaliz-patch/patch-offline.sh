#!/bin/sh

# Download all packages periodically.
./downloadall.sh

cp ./normaliz.gitignore ../Normaliz-offline/.gitignore

# common.sh is patched to point to pre-downloaded packages;
# filenames of downloaded packages have to be updated!
# The other files below are patched to get packages from this place instead of online.
cp install_scripts_opt/common.sh ../Normaliz-offline/install_scripts_opt/common.sh

cp install_scripts_opt/install_nmz_cocoa.sh ../Normaliz-offline/install_scripts_opt/install_nmz_cocoa.sh

# install_eantic_with_prerequisites.sh
cp install_scripts_opt/install_nmz_mpfr.sh ../Normaliz-offline/install_scripts_opt/install_nmz_mpfr.sh
cp install_scripts_opt/install_nmz_flint.sh ../Normaliz-offline/install_scripts_opt/install_nmz_flint.sh
cp install_scripts_opt/install_nmz_arb.sh ../Normaliz-offline/install_scripts_opt/install_nmz_arb.sh
cp install_scripts_opt/install_nmz_antic.sh ../Normaliz-offline/install_scripts_opt/install_nmz_antic.sh
cp install_scripts_opt/install_nmz_e-antic.sh ../Normaliz-offline/install_scripts_opt/install_nmz_e-antic.sh

cp install_scripts_opt/install_nmz_nauty.sh ../Normaliz-offline/install_scripts_opt/install_nmz_nauty.sh

cp -r download ../Normaliz-offline/download
