echo "Running NSYS profiling..."
nsys profile \
    --force-overwrite true \
    --output ${OUTPUT_DIR}/nsight/${OUTPUT_DIR} \
    --trace=cuda,nvtx,osrt,cudnn,cublas \
    python3 -m tensorqtl example/data/GEUVADIS.445_samples.GRCh38.20170504.maf01.filtered.nodup.chr18 \
    example/data/GEUVADIS.445_samples.expression.bed.gz \
    GEUVADIS.445_samples \
    --covariates example/data/GEUVADIS.445_samples.covariates.txt \
    --mode cis \
    --quiet \
    ${RUN_ARGS}
