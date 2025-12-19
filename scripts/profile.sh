set -e

# Get the directory where this script is located
SCRIPT_DIR="$(dirname "$0")"

COMPILE=''
RUN_PYTORCH=''
RUN_NSYS=''

while getopts "cnp" opt; do
  case $opt in
    c) COMPILE=true ;;
    n) RUN_NSYS=true ;;
    p) RUN_PYTORCH=true ;;
    \?) # Handle invalid options
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done


# Output dir

OUTPUT_DIR=''
if [ "$COMPILE" = "true" ]; then
    OUTPUT_DIR='runs/cis_compile'
else
    OUTPUT_DIR='runs/cis_raw'
fi
mkdir -p ${OUTPUT_DIR}/nsight/ ${OUTPUT_DIR}/pytorch/ ${OUTPUT_DIR}/output/

RUN_ARGS=''
if [ "$COMPILE" = "true" ]; then
    RUN_ARGS='--compile'
fi

# Nsight profiling
if [ "$RUN_NSYS" = "true" ]; then
   source "${SCRIPT_DIR}/profile_nsys.sh"
   source "${SCRIPT_DIR}/profile_ncu.sh"
fi

# Pytorch profiling
if [ "$RUN_PYTORCH" = "true" ]; then
  source "${SCRIPT_DIR}/profile_pytorch.sh"
fi
