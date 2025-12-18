set -e

COMPILE=''

while getopts "c" opt; do
  case $opt in
    c) COMPILE=true ;;
    \?) # Handle invalid options
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done


# Output dir

OUTPUT_DIR=''
if [ "$COMPILE" = "true" ]; then
    OUTPUT_DIR='cis_compile'
else
    OUTPUT_DIR='cis_raw'
fi
mkdir -p ${OUTPUT_DIR}/nsight/ ${OUTPUT_DIR}/pytorch/

RUN_ARGS=''
if [ "$COMPILE" = "true" ]; then
    RUN_ARGS='--compile'
fi

# Nsight profiling
echo "Running Nsight profiling..."
nsys profile \
    --stats=true \
    --force-overwrite true \
    --output ${OUTPUT_DIR}/nsight/${OUTPUT_DIR} \
    --trace=cuda,nvtx,osrt,cudnn,cublas \
    python3 -m tensorqtl example/data/GEUVADIS.445_samples.GRCh38.20170504.maf01.filtered.nodup.chr18 \
    example/data/GEUVADIS.445_samples.expression.bed.gz \
    GEUVADIS.445_samples \
    --covariates example/data/GEUVADIS.445_samples.covariates.txt \
    --mode cis \
    ${RUN_ARGS}


# Pytorch profiling
echo "Running Pytorch profiling..."
python3 -m tensorqtl \
  example/data/GEUVADIS.445_samples.GRCh38.20170504.maf01.filtered.nodup.chr18 \
  example/data/GEUVADIS.445_samples.expression.bed.gz \
  GEUVADIS.445_samples \
  --covariates example/data/GEUVADIS.445_samples.covariates.txt \
  --mode cis \
  --torch_profile_dir ${OUTPUT_DIR}/pytorch/ \
  ${RUN_ARGS}
