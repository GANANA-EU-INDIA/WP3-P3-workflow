#======== COMPSs
module use --append /leonardo/pub/userinternal/lsalicar/modules
ml compss/3.3.3

#======== GROMACS
module use --append /leonardo/pub/userinternal/lsalicar/spack-0.22.2-06/modules
# add gmx_mpi bin path to PATH
ml gromacs/2024.6--openmpi--4.1.6--gcc--12.2.0-cuda-12.2
export GMXBIN_NAME="gmx_mpi"
# custom FF path location
export GMXLIB=$ROOT_PATH/data

# Flags for GPU usage of gromacs
export GMX_GPU_DD_COMMS=true  # not require from Gromacs 2025 onward. Kept for retrocompatibility
export GMX_GPU_PME_PP_COMMS=true
export GMX_FORCE_UPDATE_DEFAULT_GPU=true