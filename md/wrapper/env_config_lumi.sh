# =========== ====================== =========== #
# ===========          SLURM         =========== #
# =========== ====================== =========== #
# Slurm parameters.
# These usually tend to remain unchanged between runs.
# Those that change between different execution of the
# workflow are handled by the Makefile/submit_workflow
ACCOUNT=project_465003555
QUEUE=standard-g
QOS=

# =========== ====================== =========== #
# ===========       PyCOMPSs         =========== #
# =========== ====================== =========== #
EXTRA_COMPSS_FLAGS=(
    --extra_submit_flag=--account#${ACCOUNT}
    --graph
    --summary
    --monitoring=1000
    --debug
    --keep_workingdir
    --worker_working_dir=$(pwd)
)

# COMMENTS
# - in --extra_submit_flag, spaces has to be translated into "#"
# - keep_workingdir keeps the temp directories used by the workers
# Possible useful flags
# --scheduler=es.bsc.compss.scheduler.lookahead.successors.fifo.FifoTS
# --checkpoint=es.bsc.compss.checkpoint.policies.CheckpointPolicyFinishedTasks
# --checkpoint_params=finished.tasks:1
# --checkpoint_folder=$OUTPUT_DIR/.checkpoints/
# --worker_working_dir=$OUTPUT_DIR \
# --master_working_dir=$OUTPUT_DIR \
# --provenance=$WF_PATH/md-provenance.yaml \
# --keep_workingdir \
# The following is a Policy that passes the compss tests
# --checkpoint=es.bsc.compss.checkpoint.policies.CheckpointPolicyInstantiatedGroup \
# --checkpoint_params=instantiated.group:20 \

# =========== ====================== =========== #
# ===========    HPC modules load    =========== #
# =========== ====================== =========== #
#  COMPSs
export JAVA_HOME=/users/salicari/jdk-27
ml PrgEnv-gnu/8.6.0
ml cray-python/3.11.7
ml LUMI/25.03
ml partition/G
. /projappl/project_465003555/installation/compss/3.4/compssenv

# GROMACS
# add gmx_mpi bin path to PATH
#ml GROMACS/2026.0-cpeAMD-25.03-HeFFTe-rocm-hip
ml use /appl/local/csc/modulefiles
ml gromacs/2026.0-gpu

# Flags for GPU usage of gromacs
export GMX_GPU_DD_COMMS=true  # not require from Gromacs 2025 onward. Kept for retrocompatibility
export GMX_GPU_PME_PP_COMMS=true
export GMX_FORCE_UPDATE_DEFAULT_GPU=true

export AMD_DIRECT_DISPATCH=1
export ROC_ACTIVE_WAIT_TIMEOUT=0
export MPICH_GPU_SUPPORT_ENABLED=1
export GMX_ENABLE_DIRECT_GPU_COMM=1
export GMX_FORCE_GPU_AWARE_MPI=1
export MPICH_SMP_SINGLE_COPY_MODE=CMA
export MPICH_MALLOC_FALLBACK=1

export GMXBIN_NAME="gmx_mpi" # This env var is used inside the workflow
# Custom FF path location
# https://manual.gromacs.org/2024.6/onlinehelp/gmx-pdb2gmx.html#description
export GMXLIB=$ROOT_PATH/data

if [ ! -d "$GMXLIB/charmm36-jul2022.ff" ] || [ -z "$(ls -A $GMXLIB/charmm36-jul2022.ff 2>/dev/null)" ]; then
    echo "ERROR: $GMXLIB/charmm36-jul2022.ff directory is missing or empty"
    exit 1
fi

export OMP_NUM_THREADS=8
export GPU_VENDOR=amd

# =========== ====================== =========== #
# ===========   Python environment   =========== #
# =========== ====================== =========== #
. $ROOT_PATH/.venv/bin/activate

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
EXEC_TIME_SEC=$(echo "$EXEC_TIME * 60" | bc)
TO_SUBSTRACT_SEC=$((echo "$EXEC_TIME_SEC * 5/100") | bc)
if [ "$TO_SUBSTRACT_SEC" -lt 300 ]; then
    TO_SUBSTRACT_SEC=300
fi
WALL_CLOCK_LIMIT=$((echo "$EXEC_TIME_SEC - $TO_SUBSTRACT_SEC") | bc)
