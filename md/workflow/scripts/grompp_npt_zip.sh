#/bin/bash -e

NPT_MDP=${1}
PROTEIN_EQ=${2}
TOPOLOGY=${3}
NPT_TPR=${4}

# unzip and overwrite existing files, if present, and remove original zip
unzip -u ${TOPOLOGY}.zip && rm -f ${TOPOLOGY}.zip
wait
$GMXBIN_NAME grompp -f $NPT_MDP -c $PROTEIN_EQ -r $PROTEIN_EQ -p $TOPOLOGY -o $NPT_TPR
wait
zip -r ${TOPOLOGY}.zip *.itp
