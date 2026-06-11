# =========== ====================== =========== #
# ===========          SLURM         =========== #
# =========== ====================== =========== #
# Slurm parameters.
# These usually tend to remain unchanged between runs.
# Those that change between different execution of the
# workflow are handled by the Makefile/submit_workflow
ACCOUNT=naiss2026-3-348
QUEUE=gpu
QOS=default

# =========== ====================== =========== #
# ===========    HPC modules load    =========== #
# =========== ====================== =========== #
#  COMPSs
#ml purge
#export SPACK_USER_PREFIX=/cfs/klemming/projects/supr/naiss2025-5-614/lsalicar/.local/spack
ml PDC
ml spack-user
unset SPACK_DISABLE_LOCAL_CONFIG
export SPACK_USER_PREFIX=/cfs/klemming/projects/supr/naiss2025-5-614/lsalicar/.local/spack
module use --prepend /cfs/klemming/projects/supr/naiss2025-5-614/lsalicar/.local/spack/modules/tcl/linux-sles15-zen2
ml compss

ml openmpi

#  GROMACS
# add gmx_mpi bin path to PATH
ml gromacs/2026.1-gpu
# Flags for GPU usage of gromacs
#export GMX_GPU_DD_COMMS=true  # not require from Gromacs 2025 onward. Kept for retrocompatibility
#export GMX_GPU_PME_PP_COMMS=true
#export GMX_FORCE_UPDATE_DEFAULT_GPU=true

export GMXBIN_NAME="gmx_mpi" # This env var is used inside the workflow
# Custom FF path location
# https://manual.gromacs.org/2024.6/onlinehelp/gmx-pdb2gmx.html#description
export GMXLIB=$ROOT_PATH/data

# =========== ====================== =========== #
# ===========   Python environment   =========== #
# =========== ====================== =========== #
. /cfs/klemming/projects/supr/naiss2025-5-614/lsalicar/WP3-P3-workflow/md/.venv/bin/activate

# =========== ====================== =========== #
# =========== DATA and WORKFLOW PATH =========== #
# =========== ====================== =========== #
WF_PATH=$ROOT_PATH/workflow
DATA_PATH=$ROOT_PATH/data
WORKFLOW_FILE=$WF_PATH/$WORKFLOWNAME.py

# =========== ====================== =========== #
# ===========       MISCELLANEA      =========== #
# =========== ====================== =========== #
# Allow execution of the pdb2gmx wrapper and
# other scripts
export PATH=$PATH:$WF_PATH/scripts

# convert EXEC_TIME into seconds and remove 5%
# This ensure that COMPSs terminates the tasks before the
# allocated time from Slurms ends.
# https://compss-doc.readthedocs.io/en/stable/Sections/03_Execution_Environments/03_Deployments/01_Master_worker/02_Supercomputers/01_Executing.html#compss-job-submission
# Give at least 5 minute
EXEC_TIME_SEC=$((echo "$EXEC_TIME * 60") | bc)
TO_SUBSTRACT_SEC=$((echo "$EXEC_TIME_SEC * 5/100") | bc)
if [ "$TO_SUBSTRACT_SEC" -lt 300 ]; then
    TO_SUBSTRACT_SEC=300
fi
WALL_CLOCK_LIMIT=$((echo "$EXEC_TIME_SEC - $TO_SUBSTRACT_SEC") | bc)
