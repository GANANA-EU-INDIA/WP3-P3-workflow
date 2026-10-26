#!/bin/bash
# gpu_wrap.sh: bind the GPU and local cores COMPSs assigned to this task, then exec the command.
# Needs only bash and taskset (util-linux); no special permissions.
# Env: GPU_VENDOR=nvidia|amd (default nvidia), CLUSTERNAME selects the core-locality table.
gpus=${COMPSS_BINDED_GPUS:-}; g=${gpus%%,*}; n=${COMPSS_NUM_CPUS:-0}
vendor=${GPU_VENDOR:-nvidia}
extra=(); first=; list=; core0=(); max=0
[ -z "${GPU_VENDOR:-}" ] && echo "[gpu_wrap] GPU_VENDOR unset, assuming nvidia" >&2

# core0[i] = first usable core local to GPU i; max = usable cores in that block
case "${CLUSTERNAME,,}" in
  lumi)               core0=(49 57 17 25 1 9 33 41); max=7 ;;   # core 0 of each CCD disabled
  mn5*|marenostrum*)  core0=(0 20 40 60); max=20 ;;              # from `nvidia-smi topo -m`
  leonardo*)          ;;  # all 4 GPUs on one NUMA node: no table, use COMPSs cores
  *) echo "[gpu_wrap] no locality table for CLUSTERNAME='${CLUSTERNAME-}', using COMPSs cores" >&2 ;;
esac

if [ -n "$gpus" ]; then
  case $vendor in
    nvidia) export CUDA_VISIBLE_DEVICES=$gpus GPU_DEVICE_ORDINAL=$gpus ;;
    amd)    export ROCR_VISIBLE_DEVICES=$gpus
            unset CUDA_VISIBLE_DEVICES GPU_DEVICE_ORDINAL HIP_VISIBLE_DEVICES ;;
    *)      echo "[gpu_wrap] unknown GPU_VENDOR='$vendor' (use nvidia|amd): GPU not bound" >&2 ;;
  esac
fi

# Cores local to the GPU if the cluster is known, otherwise the ones COMPSs picked.
if [ -n "$g" ] && [ "$g" -lt "${#core0[@]}" ] && [ "$n" -ge 1 ] && [ "$n" -le "$max" ]; then
  first=${core0[g]}; list="$first-$((first + n - 1))"
elif [ -n "${COMPSS_BINDED_CPUS:-}" ]; then
  list=${COMPSS_BINDED_CPUS// /}; first=${list%%[,-]*}
fi
if [ -n "$first" ]; then
  taskset -cp "$list" $$ >/dev/null 2>&1
  extra=(-pinoffset "$first" -pinstride 1)
fi

echo "[gpu_wrap] $(hostname) vendor=$vendor cluster=${CLUSTERNAME-unset} GPUS=$gpus CPUS_COMPSS=${COMPSS_BINDED_CPUS-unset} cores=${list:-none} $(grep Cpus_allowed_list /proc/self/status) extra=${extra[*]-none}" >&2
exec "$@" "${extra[@]}"