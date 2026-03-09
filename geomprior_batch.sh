#!/bin/bash

# ---------- default values ----------
DATASET_BASE_DEFAULT="./dataset/MuSHRoom"
SCENES_DEFAULT="classroom,coffee_room,honka,kokko,vr_room"
GPUS_DEFAULT="0,1,2,3,4"

# ---------- parse args ----------
DATASET_BASE=${DATASET_BASE_DEFAULT}
SCENES_STR=${SCENES_DEFAULT}
GPUS_STR=${GPUS_DEFAULT}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dataset_base)
      DATASET_BASE="$2"; shift 2 ;;
    --scenes)
      SCENES_STR="$2"; shift 2 ;;
    --gpus)
      GPUS_STR="$2"; shift 2 ;;
    *)
      echo "Unknown option: $1"
      exit 1 ;;
  esac
done

# ---------- string -> array ----------
IFS=',' read -r -a SCENES <<< "${SCENES_STR}"
IFS=',' read -r -a GPUS   <<< "${GPUS_STR}"

# ---------- sanity check ----------
if [[ ${#GPUS[@]} -eq 0 ]]; then
  echo "Error: No GPUs specified"
  exit 1
fi

# ---------- main loop ----------
for i in "${!SCENES[@]}"; do
  SCENE=${SCENES[$i]}
  # Circular allocation of GPU
  GPU=${GPUS[$((i % ${#GPUS[@]}))]}

  echo "Get geometry prior ${SCENE} on GPU ${GPU}"

  CUDA_VISIBLE_DEVICES=${GPU} \
  python run_geomprior.py -s "${DATASET_BASE}/${SCENE}" --group_size 25 --vis &

  # If the current task count reaches the number of GPUs,
  # wait for all tasks to complete
  if (( (i + 1) % ${#GPUS[@]} == 0 )); then
    wait
  fi

done

wait

echo "All done."
