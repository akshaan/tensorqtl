# syntax=docker/dockerfile:1.4
# Dockerfile for tensorQTL
# https://gitlab.com/nvidia/container-images/cuda/blob/master/doc/unsupported-tags.md
FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404

# Install base system dependencies with cache mount
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
        software-properties-common \
        apt-transport-https \
        build-essential \
        cmake \
        curl \
        libboost-all-dev \
        libbz2-dev \
        libcurl3-dev \
        liblzma-dev \
        libncurses5-dev \
        libssl-dev \
        python3 \
        python3-pip \
        sudo \
        unzip \
        wget \
        zlib1g-dev \
        gnupg

# Install R dependencies and R
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    wget -q http://ftp.osuosl.org/pub/ubuntu/pool/main/i/icu/libicu70_70.1-2_amd64.deb \
         http://archive.ubuntu.com/ubuntu/pool/main/t/tiff/libtiff5_4.3.0-6_amd64.deb && \
    dpkg -i libicu70_70.1-2_amd64.deb libtiff5_4.3.0-6_amd64.deb && \
    rm libicu70_70.1-2_amd64.deb libtiff5_4.3.0-6_amd64.deb && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && \
    add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu jammy-cran40/' && \
    apt-get update && apt-get install -y --no-install-recommends r-base r-base-dev

# Install Nsight Systems
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    echo "deb http://developer.download.nvidia.com/devtools/repos/ubuntu$(source /etc/lsb-release; echo "$DISTRIB_RELEASE" | tr -d .)/$(dpkg --print-architecture) /" | tee /etc/apt/sources.list.d/nvidia-devtools.list && \
    apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub && \
    apt-get update && \
    apt-get install -y --no-install-recommends nsight-systems-cli

# Install R packages
ENV R_LIBS_USER=/opt/R/4.0
RUN --mount=type=cache,target=/root/.cache/R,sharing=locked \
    Rscript -e 'if (!requireNamespace("BiocManager", quietly = TRUE)) {install.packages("BiocManager")}; BiocManager::install("qvalue");'

# Build htslib with parallel compilation
RUN cd /opt && \
    wget -q --no-check-certificate https://github.com/samtools/htslib/releases/download/1.19/htslib-1.19.tar.bz2 && \
    tar -xf htslib-1.19.tar.bz2 && rm htslib-1.19.tar.bz2 && cd htslib-1.19 && \
    ./configure --enable-libcurl --enable-s3 --enable-plugins --enable-gcs && \
    make -j$(nproc) && make install && make clean && \
    cd /opt && rm -rf htslib-1.19

# Build bcftools with parallel compilation
RUN cd /opt && \
    wget -q --no-check-certificate https://github.com/samtools/bcftools/releases/download/1.19/bcftools-1.19.tar.bz2 && \
    tar -xf bcftools-1.19.tar.bz2 && rm bcftools-1.19.tar.bz2 && cd bcftools-1.19 && \
    ./configure --with-htslib=system && make -j$(nproc) && make install && make clean && \
    cd /opt && rm -rf bcftools-1.19

# Clean up apt cache and temporary files
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    apt-get clean && \
    apt-get autoremove -y

# Install Python package (this layer changes most frequently, so it's last)
WORKDIR /app
RUN git clone https://github.com/akshaan/tensorqtl.git .
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked \
    pip3 install -e .
