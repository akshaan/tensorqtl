SCRIPT_DIR="$(dirname "$0")"
RUN_ARGS="${RUN_ARGS} --profile"

echo "Running Pytorch profiling..."
source ${SCRIPT_DIR}/run.sh