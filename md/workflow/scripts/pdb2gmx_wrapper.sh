#/bin/bash -e

# Leonardo Salicari: 2025/09
# This wrapper solve a practival problem:
# When processing a PDB with gromacs the number of
# itp files can varies depending on the number of polymer
# chains in the PDB.
# From a data provenance and track processes point of view,
# this creates a problem: keep track of these files.
# The workaround is the following: have everything on a single
# top file.
# This creates a top file that is difficult to read for a
# human but that has everything inside a single file.

PROTEIN=${1}
STRUCTURE=${2}
TOPOLOGY=${3}
FF=${4}
WATER=${5}

$GMXBIN_NAME pdb2gmx -f ${PROTEIN} -o ${STRUCTURE} -p ${TOPOLOGY} -ff ${FF} -water ${WATER} -ignh

sed_include() {
    # Substitute itp's content inside .top file
    for source_itp in *.itp; do
        tmp_file=$(mktemp)

        target_string="#include[[:space:]]*\"${source_itp}\"[[:space:]]*"
        # escaped_target_string=$(printf '%s\n' "$target_string" | sed 's/[.[\*^$\/]/\\&/g')

        sed "/${target_string}/{
            r ${source_itp}
            d
        }" "${1}" > "${tmp_file}"

        mv "${tmp_file}" "${1}"
    done
}

wait
sed_include ${TOPOLOGY}
wait
# a second call is necessary for the posre*.itp files
# to expand correctly all #include statements
sed_include ${TOPOLOGY}
