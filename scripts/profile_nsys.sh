SCRIPT_DIR="$(dirname "$0")"

echo "Running NSYS profiling..."
nsys profile \
    --force-overwrite true \
    --output ${OUTPUT_DIR}/nsight/${OUTPUT_DIR} \
    --trace=cuda,nvtx,osrt,cudnn,cublas \
    source ${SCRIPT_DIR}/run.sh