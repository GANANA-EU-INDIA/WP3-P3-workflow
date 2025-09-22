#/bin/bash -e

PROTEIN=${1}
STRUCTURE=${2}
TOPOLOGY=${3}

$GMXBIN_NAME pdb2gmx -f ${PROTEIN} -o ${STRUCTURE} -p ${TOPOLOGY} -ignh -ff charmm27 -water tip3p
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
