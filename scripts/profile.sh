nsys profile \
    --stats=true \
    --force-overwrite true \
    --output cis_torch_compile \
    --trace=cuda,nvtx,osrt,cudnn,cublas \
    --cudabacktrace=all \
    --python-backtrace=cuda \
    python my_script.py
