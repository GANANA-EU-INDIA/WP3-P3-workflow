#/bin/bash -e

PROTEIN=${1}
STRUCTURE=${2}
TOPOLOGY=${3}

# prepend path to custom FF to make it available to pdb2gmx
# https://manual.gromacs.org/2024.6/onlinehelp/gmx-pdb2gmx.html#description
GMXLIB=$ROOT_PATH/data $GMXBIN_NAME pdb2gmx -f ${PROTEIN} -o ${STRUCTURE} -p ${TOPOLOGY} -ff "charmm36-jul2022" -water tip3p -ignh
wait
zip -r ${TOPOLOGY}.zip *.itp

# =========================
# USAGE
# pdb2gmx_zip.sh protein.pdb structure.gro topology.top
#
# This script and similar act as a thin wrapper to handle the apriori not known
# number of .itp files produced by gromacs. The idea is keep track of the single
# .zip file, containing these .itp.
# =========================
