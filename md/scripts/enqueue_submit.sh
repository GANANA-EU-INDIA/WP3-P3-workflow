#!/bin/bash -e

#========= Arguments =========#
usage() {
    echo "Usage: $0 WORKFLOWNAME NODES CPU_PER_NODE"
    echo
    echo "Arguments (arguments follows Slurm terminology):"
    echo "  WORKFLOWNAME   Name of the workflow (e.g., md)"
    echo "  NODES          Number of nodes to use"
    echo "  CPUS_PER_NODE   Number of CPUs per node"
    echo
    echo "Example:"
    echo "  $0 md 2 32"
}

# If first argument is --help, show usage and exit
if [[ "$1" == "--help" ]]; then
    usage
    exit 0
fi

# Check if correct number of arguments provided
if [[ $# -ne 3 ]]; then
    echo "Error: Invalid number of arguments."
    usage
    exit 1
fi

WORKFLOWNAME=$1
export NODES=$2
export CPUS_PER_NODE=$3

#========= Setup envs and paths =========#
THIS_SCRIPT_PARENT_PATH=$(dirname "$(realpath "$0")")
ROOT_PATH=$(dirname "$THIS_SCRIPT_PARENT_PATH")

# Prepare module env
. $THIS_SCRIPT_PARENT_PATH/module_setup.sh

# Source python env
. $(dirname "$ROOT_PATH")/envs/md/bin/activate

# Source slurm configs
. $THIS_SCRIPT_PARENT_PATH/slurm_config.sh

# Paths to files
WF_PATH=$ROOT_PATH/workflow
DATA_PATH=$ROOT_PATH/data

# TODO: to be removed after update from zip files to directories track
# Add script dir into path
export PATH=$PATH:$WF_PATH/scripts

EX_FILE=$WF_PATH/${1}.py

# Slurm arguments first, then COMPSs ones
enqueue_compss \
    --job_name=${WORKFLOWNAME} \
    --exec_time=20 \
    --num_nodes=${NODES} \
    --cpus_per_node=${CPUS_PER_NODE} \
    --gpus_per_node=1 \
    --queue=${QUEUE} \
    --qos=${QOS} \
    --extra_submit_flag=--account#${ACCOUNT} \
    --wall_clock_limit=1100 \
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
