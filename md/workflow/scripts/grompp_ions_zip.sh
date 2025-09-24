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

