#/bin/bash -e

EMIN_MDP=${1}
PROTEIN_IONS=${2}
TOPOLOGY=${3}
EMIN_TPR=${4}

# unzip and overwrite existing files, if present, and remove original zip
unzip -u ${TOPOLOGY}.zip && rm -f ${TOPOLOGY}.zip
wait
$GMXBIN_NAME grompp -f $EMIN_MDP -c $PROTEIN_IONS -p $TOPOLOGY -o $EMIN_TPR
wait
zip -r ${TOPOLOGY}.zip *.itp
