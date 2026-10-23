#!/bin/bash
# gpu_wrap.sh: bind the GPU(s) and cores COMPSs assigned to this task, then exec the command.
# Vendor is auto-detected from the device node; override with GPU_VENDOR=nvidia|amd.
vendor=${GPU_VENDOR:-}
if [ -z "$vendor" ]; then
  if   [ -e /dev/kfd ];       then vendor=amd
  elif [ -e /dev/nvidiactl ]; then vendor=nvidia
  else vendor=unknown; fi
fi

echo "[gpu_wrap] $(hostname) vendor=$vendor GPUS=${COMPSS_BINDED_GPUS-unset} CPUS=${COMPSS_BINDED_CPUS-unset} CVD_in=${CUDA_VISIBLE_DEVICES-unset} ROCR_in=${ROCR_VISIBLE_DEVICES-unset} HIP_in=${HIP_VISIBLE_DEVICES-unset}" >&2
echo "[gpu_wrap] $(grep Cpus_allowed_list /proc/self/status)" >&2

if [ -n "${COMPSS_BINDED_GPUS:-}" ]; then
  case $vendor in
    nvidia)
      export CUDA_VISIBLE_DEVICES=$COMPSS_BINDED_GPUS
      export GPU_DEVICE_ORDINAL=$COMPSS_BINDED_GPUS
      ;;
    amd)
      export ROCR_VISIBLE_DEVICES=$COMPSS_BINDED_GPUS
      # Only one variable should select the device (see note below).
      unset CUDA_VISIBLE_DEVICES GPU_DEVICE_ORDINAL HIP_VISIBLE_DEVICES
      # On LUMI: GPU binding only applies with a full-node allocation (the standard-g partition, or --exclusive on others)
      # This should be the default taken from the cfg file of the Cluster.
      # NOTE: this approach does not account for core and GCD (gpus) locality. See Lumi doc for more info.
      ;;
  esac
fi

extra=()
if [ -n "${COMPSS_BINDED_CPUS:-}" ]; then
  first=${COMPSS_BINDED_CPUS%%[,-]*}
  extra=(-pinoffset "$first" -pinstride 1)
fi
echo "[gpu_wrap] extra mdrun args: ${extra[*]-none}" >&2
exec "$@" "${extra[@]}"