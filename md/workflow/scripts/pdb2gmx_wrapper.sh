#/bin/bash -e

PROTEIN=${1}
STRUCTURE=${2}
TOPOLOGY=${3}

$GMXBIN_NAME pdb2gmx -f ${PROTEIN} -o ${STRUCTURE} -p ${TOPOLOGY} -ff "charmm36-jul2022" -water tip3p -ignh

wait

sed_include() {
    # Substitute itp's content inside .top file
    for source_itp in *.itp; do
        echo "DEBUGGG: ${source_itp}"
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

sed_include ${TOPOLOGY}
wait
# a second call is necessary for the posre*.itp files
# to expand correctly all #include statements
sed_include ${TOPOLOGY}
