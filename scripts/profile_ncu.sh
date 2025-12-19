SCRIPT_DIR="$(dirname "$0")"

echo "Running NCU profiling..."
ncu --metrics \
    dram__throughput.avg.pct_of_peak_sustained_elapsed,\
    sm__throughput.avg.pct_of_peak_sustained_elapsed,\
    smsp__stall_long_scoreboard.avg.pct \
    source ${SCRIPT_DIR}/run.sh