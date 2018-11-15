# This dockerfile creates the environmnent to build the conda package in CentOS 6
#

FROM conda/miniconda3-centos7

RUN yum install -y autoconf \
    automake \
    curl \
    git \
    gcc \
    gcc-c++ \
    graphviz \
    atlas-devel \
    libtool \
    make \
    pkgconfig \
    subversion \
    unzip \
    wget \
    zlib-devel \
    vim \
    gmp-devel \
    mpfr-devel \
    libmpc-devel \
    bzip2 \
    openssl \
    openssl-devel \
    patch \
    && conda install conda-build ninja setuptools pip pyparsing numpy

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
RUN cd ~ \
    && wget https://cmake.org/files/v3.6/cmake-3.6.2.tar.gz \
    && tar -zxvf cmake-3.6.2.tar.gz \
    && cd cmake-3.6.2 \
    && ./bootstrap --prefix=/usr/local \
    && make \
    && make install \
    && rm -rf ~/cmake-3.6.2.tar.gz \
    && rm -rf ~/cmake-3.6.2

# Install protobuf, clif
RUN cd ~ \
    && git clone https://github.com/pykaldi/pykaldi.git \
    && cd pykaldi/tools \
    && ./install_protobuf.sh \
    && ./install_clif.sh

RUN cd ~ \
    && git clone https://github.com/pykaldi/conda-package.git

