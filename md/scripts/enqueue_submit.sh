#!/bin/bash -e

#========= Arguments =========#
usage() {
    echo "Usage: $0 WORKFLOWNAME NODES CPU_PER_NODE EXEC_TIME"
    echo
    echo "Arguments (arguments follows Slurm terminology):"
    echo "  WORKFLOWNAME        Name of the workflow (e.g., md)"
    echo "  NODES               Number of nodes to use"
    echo "  CPUS_PER_NODE       Number of CPUs per node"
    echo "  EXEC_TIME           Time before terminating execution (in minutes, Slurm directive). COMPSs will terminate tasks in 5% less time (or at least 5 minutes) compare to EXEC_TIME, to allow COMPSs to save all data."
    echo "  GRES_GPUS           Number of GPUs per node"
    echo
    echo "Example:"
    echo "  $0 md 2 32 20 1"
}

# If first argument is --help, show usage and exit
if [[ "$1" == "--help" ]]; then
    usage
    exit 0
fi

# Check if correct number of arguments provided
if [[ $# -ne 5 ]]; then
    echo "Error: Invalid number of arguments."
    usage
    exit 1
fi

WORKFLOWNAME=$1
export NODES=$2
export CPUS_PER_NODE=$3
export EXEC_TIME=$4
export GRES_GPUS=$5

#========= Setup envs and paths =========#
export THIS_SCRIPT_PARENT_PATH=$(dirname "$(realpath "$0")")
export ROOT_PATH=$(dirname "$THIS_SCRIPT_PARENT_PATH")

# Prepare module env
. $THIS_SCRIPT_PARENT_PATH/module_setup.sh

# Source python env
. $(dirname "$ROOT_PATH")/envs/md/bin/activate

# Source slurm configs
. $THIS_SCRIPT_PARENT_PATH/slurm_config.sh

# Paths to files
WF_PATH=$ROOT_PATH/workflow
DATA_PATH=$ROOT_PATH/data

# Add script dir into path
export PATH=$PATH:$WF_PATH/scripts

EX_FILE=$WF_PATH/${1}.py

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

# Slurm arguments first, then COMPSs ones
enqueue_compss \
    --job_name=${WORKFLOWNAME} \
    --exec_time=${EXEC_TIME} \
    --num_nodes=${NODES} \
    --cpus_per_node=${CPUS_PER_NODE} \
    --gpus_per_node=${GRES_GPUS} \
    --queue=${QUEUE} \
    --qos=${QOS} \
    --extra_submit_flag=--account#${ACCOUNT} \
    --wall_clock_limit=$WALL_CLOCK_LIMIT \
    --log_dir=$DATA_PATH \
    --master_working_dir=$DATA_PATH \
    --worker_working_dir=$DATA_PATH \
    --scheduler=es.bsc.compss.scheduler.lookahead.successors.fifo.FifoTS \
    --lang=python \
    --pythonpath=$WF_PATH \
    --classpath=$WF_PATH \
    --checkpoint=es.bsc.compss.checkpoint.policies.CheckpointPolicyFinishedTasks \
    --checkpoint_params=finished.tasks:1 \
    --checkpoint_folder=$DATA_PATH/.checkpoints/ \
    --graph \
    --debug \
    --monitoring=1000 \
    --summary \
    --keep_workingdir \
    $EX_FILE -d $DATA_PATH/input -o $DATA_PATH/output

# COMMENTS
# - lang, despite the documentation saying that the program infers it, it fails. Probably due to the arguments
# - be very careful with trailing white spaces after the escape char \, they cause bash to not read the following line
# - in --extra_submit_flag, spaces has to be translated into "#"
# - keep_workingdir keeps the temp directories used by the workers

# Parking space for probabily useful arguments
    # --provenance \
    # The following is a Policy that passes the compss tests
    # --checkpoint=es.bsc.compss.checkpoint.policies.CheckpointPolicyInstantiatedGroup \
    # --checkpoint_params=instantiated.group:20 \

