#!/bin/bash -e

# This is a thin wrapper around the COMPSs program
# enqueue_compss
# This is the one tha actualy submit the workflow
# to Slurm and execute the COMPSs runtime.
# This scripts serves to prepare the shell in a HPC
# environment to run COMPSs.

# =========== ====================== =========== #
# ===========       ARGUMENTS        =========== #
# =========== ====================== =========== #
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

export WORKFLOWNAME=$1
export NODES=$2
export CPUS_PER_NODE=$3
export EXEC_TIME=$4
export GRES_GPUS=$5

# =========== ====================== =========== #
# ===========     ENVS and PATHS     =========== #
# =========== ====================== =========== #
export THIS_SCRIPT_PARENT_PATH=$(dirname "$(realpath "$0")")
export ROOT_PATH=$(dirname "$THIS_SCRIPT_PARENT_PATH")

# Setup shell environement for workflow execution.
# See the file for more info and configurations.
. $THIS_SCRIPT_PARENT_PATH/env_config.sh

# =========== ====================== =========== #
# =========== CALL to ENQUEUE_COMPSS =========== #
# =========== ====================== =========== #

# Slurm arguments first, then COMPSs ones
enqueue_compss \
    --job_name=${WORKFLOWNAME} \
    --exec_time=${EXEC_TIME} \
    --num_nodes=${NODES} \
    --cpus_per_node=${CPUS_PER_NODE} \
    --gpus_per_node=${GRES_GPUS} \
    --extra_submit_flag=--account#${ACCOUNT} \
    --queue=${QUEUE} \
    --qos=${QOS} \
    --wall_clock_limit=$WALL_CLOCK_LIMIT \
    --lang=python \
    --pythonpath=$WF_PATH \
    --classpath=$WF_PATH \
    --master_working_dir=$DATA_PATH \
    --worker_working_dir=$DATA_PATH \
    --log_dir=$DATA_PATH \
    --scheduler=es.bsc.compss.scheduler.lookahead.successors.fifo.FifoTS \
    --checkpoint=es.bsc.compss.checkpoint.policies.CheckpointPolicyFinishedTasks \
    --checkpoint_params=finished.tasks:1 \
    --checkpoint_folder=$DATA_PATH/.checkpoints/ \
    --graph \
    --summary \
    --monitoring=1000 \
    --keep_workingdir \
    --debug \
    $WORKFLOW_FILE -d $DATA_PATH/input -o $DATA_PATH/output

# COMMENTS
# - lang, despite the documentation saying that the program infers it, it fails. Probably due to the arguments
# - be very careful with trailing white spaces after the escape char \, they cause bash to not read the following line
# - in --extra_submit_flag, spaces has to be translated into "#"
# - keep_workingdir keeps the temp directories used by the workers

# Parking space for probabily useful arguments
    # --provenance=$WF_PATH/md-provenance.yaml \
    # The following is a Policy that passes the compss tests
    # --checkpoint=es.bsc.compss.checkpoint.policies.CheckpointPolicyInstantiatedGroup \
    # --checkpoint_params=instantiated.group:20 \

