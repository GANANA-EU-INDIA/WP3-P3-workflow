#/bin/bash -e

NVT_MDP=${1}
PROTEIN_EQ=${2}
TOPOLOGY=${3}
NVT_TPR=${4}

# unzip and overwrite existing files, if present, and remove original zip
unzip -u ${TOPOLOGY}.zip && rm -f ${TOPOLOGY}.zip
wait
$GMXBIN_NAME grompp -f $NVT_MDP -c $PROTEIN_EQ -r $PROTEIN_EQ -p $TOPOLOGY -o $NVT_TPR
wait
zip -r ${TOPOLOGY}.zip *.itp
