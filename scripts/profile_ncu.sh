echo "Running NCU profiling..."
ncu --metrics \
dram__throughput.avg.pct_of_peak_sustained_elapsed,\
sm__throughput.avg.pct_of_peak_sustained_elapsed,\
smsp__stall_long_scoreboard.avg.pct \
python3 -m tensorqtl \
  example/data/GEUVADIS.445_samples.GRCh38.20170504.maf01.filtered.nodup.chr18 \
  example/data/GEUVADIS.445_samples.expression.bed.gz \
  GEUVADIS.445_samples \
  --covariates example/data/GEUVADIS.445_samples.covariates.txt \
  --mode cis \
  --torch_profile_dir ${OUTPUT_DIR}/pytorch/ \
  ${RUN_ARGS}
