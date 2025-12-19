OUTPUT_DIR=${OUTPUT_DIR:-./runs/run_$(date +%Y%m%d_%H%M%S)}

python3 -m tensorqtl example/data/GEUVADIS.445_samples.GRCh38.20170504.maf01.filtered.nodup.chr18 \
    example/data/GEUVADIS.445_samples.expression.bed.gz \
    GEUVADIS.445_samples \
    --covariates example/data/GEUVADIS.445_samples.covariates.txt \
    --mode cis \
    --quiet \
    --output_dir ${OUTPUT_DIR}/output/ \
    --torch_profile_dir ${OUTPUT_DIR}/pytorch/ \
    ${RUN_ARGS}