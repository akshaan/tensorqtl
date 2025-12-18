nsys profile \
    --stats=true \
    --force-overwrite true \
    --output cis_torch_compile \
    --trace=cuda,nvtx,osrt,cudnn,cublas \
    --cudabacktrace=all \
    --python-backtrace=cuda \
    --python-sampling=true \
    python3 -m tensorqtl example/data/GEUVADIS.445_samples.GRCh38.20170504.maf01.filtered.nodup.chr18 \
    example/data/GEUVADIS.445_samples.expression.bed.gz \
    GEUVADIS.445_samples \
    --covariates example/data/GEUVADIS.445_samples.covariates.txt \
    --mode cis
