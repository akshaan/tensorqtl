# Dockerfile for tensorQTL
# https://gitlab.com/nvidia/container-images/cuda/blob/master/doc/unsupported-tags.md
FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404

RUN apt-get update && apt-get install -y software-properties-common && \
    apt-get update && apt-get install -y \
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
        zlib1g-dev

# R
RUN wget http://ftp.osuosl.org/pub/ubuntu/pool/main/i/icu/libicu70_70.1-2_amd64.deb && \
    sudo dpkg -i libicu70_70.1-2_amd64.deb && \
    wget http://archive.ubuntu.com/ubuntu/pool/main/t/tiff/libtiff5_4.3.0-6_amd64.deb && \
    sudo dpkg -i libtiff5_4.3.0-6_amd64.deb && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && \
    add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu jammy-cran40/' && \
    apt-get update && sudo apt-get install -y r-base r-base-dev && \
    rm libicu70_70.1-2_amd64.deb libtiff5_4.3.0-6_amd64.deb

# Nsight
RUN apt-get update && \
    apt-get install -y --no-install-recommends gnupg && \
    echo "deb http://developer.download.nvidia.com/devtools/repos/ubuntu$(source /etc/lsb-release; echo "$DISTRIB_RELEASE" | tr -d .)/$(dpkg --print-architecture) /" | tee /etc/apt/sources.list.d/nvidia-devtools.list && \
    apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub && \
    apt-get update && \
    apt-get install -y nsight-systems-cli
    
ENV R_LIBS_USER=/opt/R/4.0
RUN Rscript -e 'if (!requireNamespace("BiocManager", quietly = TRUE)) {install.packages("BiocManager")}; BiocManager::install("qvalue");'

RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/

# htslib
RUN cd /opt && \
    wget --no-check-certificate https://github.com/samtools/htslib/releases/download/1.19/htslib-1.19.tar.bz2 && \
    tar -xf htslib-1.19.tar.bz2 && rm htslib-1.19.tar.bz2 && cd htslib-1.19 && \
    ./configure --enable-libcurl --enable-s3 --enable-plugins --enable-gcs && \
    make && make install && make clean

# bcftools
RUN cd /opt && \
    wget --no-check-certificate https://github.com/samtools/bcftools/releases/download/1.19/bcftools-1.19.tar.bz2 && \
    tar -xf bcftools-1.19.tar.bz2 && rm bcftools-1.19.tar.bz2 && cd bcftools-1.19 && \
    ./configure --with-htslib=system && make && make install && make clean

# clone repo
WORKDIR /app
RUN git clone https://github.com/broadinstitute/tensorqtl.git .
RUN ./scripts/start.sh
