# This dockerfile creates the environmnent to build the conda package in CentOS 6
#

FROM conda/miniconda3-centos7

RUN yum install -y atlas-devel \
    autoconf \
    automake \
    bzip2 \
    curl \
    curl-devel \
    git \
    gcc \
    gcc-c++ \
    gettext-devel \
    gmp-devel \
    graphviz \
    libmpc-devel \
    libtool \
    make \
    mpfr-devel \
    #    openssl \
    #    openssl-devel \
    ncurses-devel \
    patch \
    perl-CPAN \
    perl-devel \
    pkgconfig \
    sox \
    subversion \
    unzip \
    vim \
    wget \
    zlib-devel \
    && conda install conda-build anaconda-client ninja setuptools pip pyparsing numpy cmake git

# Install gcc 5.4.0
# RUN cd ~ \
#     && curl https://ftp.gnu.org/gnu/gcc/gcc-5.4.0/gcc-5.4.0.tar.bz2 -O \
#     && tar xvfj gcc-5.4.0.tar.bz2 \
#     && mkdir gcc-5.4.0-build \
#     && cd gcc-5.4.0-build \
#     && ../gcc-5.4.0/configure --enable-languages=c,c++ --disable-multilib \
#     && make -j12 \
#     && make install \
#     && rm -rf ~/gcc-5.4.0.tar.bz2 \
#     && rm -rf ~/gcc-5.4.0-build \
#     && rm -rf ~/gcc-5.4.0

# ENV LD_LIBRARY_PATH="/usr/local/lib64:${LD_LIBRARY_PATH}"
# ENV PATH="/usr/local/bin:${PATH}"

# Install cmake3
#RUN cd ~ \
#    && wget https://cmake.org/files/v3.6/cmake-3.6.2.tar.gz \
#    && tar -zxvf cmake-3.6.2.tar.gz \
#    && cd cmake-3.6.2 \
#    && ./bootstrap --prefix=/usr/local \
#    && make \
#    && make install \
#    && rm -rf ~/cmake-3.6.2.tar.gz \
#    && rm -rf ~/cmake-3.6.2

# Install git
#RUN cd ~ \
#    && wget http://github.com/git/git/archive/v2.8.0.tar.gz \
#    && tar -zxvf v2.8.0.tar.gz \
#    && cd git-2.8.0 \
#    && make configure \
#    && ./configure --prefix=/usr/local \
#    && make install \
#    && rm -rf ~/v2.8.0.tar.gz \
#    && rm -rf ~/git-2.8.0

# Install protobuf, clif
RUN cd ~ \
    && git clone https://github.com/pykaldi/pykaldi.git \
    && cd pykaldi/tools \
    && ./install_protobuf.sh \
    && ./install_clif.sh


###########################################
# Install CUDA 9
# From: https://gitlab.com/nvidia/cuda/tree/centos7/9.0
###########################################
RUN NVIDIA_GPGKEY_SUM=d1be581509378368edeec8c1eb2958702feedf3bc3d17011adbf24efacce4ab5 && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/7fa2af80.pub | sed '/^Version/d' > /etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA && \
    echo "$NVIDIA_GPGKEY_SUM  /etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA" | sha256sum -c --strict -

RUN curl https://gitlab.com/nvidia/container-images/cuda/raw/centos7/9.0/base/cuda.repo > /etc/yum.repos.d/cuda.repo

ENV CUDA_VERSION 9.0.176
ENV CUDA_PKG_VERSION 9-0-$CUDA_VERSION-1

RUN yum install -y \
        cuda-cudart-$CUDA_PKG_VERSION && \
    ln -s cuda-9.0 /usr/local/cuda && \
    rm -rf /var/cache/yum/*

RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

RUN yum install -y \
    cuda-libraries-$CUDA_PKG_VERSION \
    cuda-cublas-9-0-9.0.176.4-1 && \
    rm -rf /var/cache/yum/*

#COPY .condarc /root

# Disable cache (via --build-arg CACHEBUST=$(date +%s))
ARG CACHEBUST=1

RUN cd ~ \
    && git clone https://github.com/pykaldi/conda-package.git


WORKDIR "/root/conda-package"
ENTRYPOINT ["bash", "anaconda_upload.sh"]
CMD ["pykaldi"]
