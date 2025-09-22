#/bin/bash -e

IONS=${1}
PROTEIN_SOLVATED=${2}
TOPOLOGY=${3}
IONS_TPR=${4}

# unzip and overwrite existing files, if present, and remove original zip
unzip -u ${TOPOLOGY}.zip && rm -f ${TOPOLOGY}.zip
wait
$GMXBIN_NAME grompp -f $IONS -c $PROTEIN_SOLVATED -p $TOPOLOGY -o $IONS_TPR
wait
zip -r ${TOPOLOGY}.zip *.itp

# =========================
# USAGE
# grompp_ions_zip.sh protein.pdb structure.gro topology.top
# 
# This script and similar act as a thin wrapper to handle the apriori not known
# number of .itp files produced by gromacs. The idea is keep track of the single 
# .zip file, containing these .itp.
# =========================
