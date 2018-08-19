# This file was generated using the following command:
# ./configure --shared

CONFIGURE_VERSION := 7

# Toolchain configuration

CXX = g++
AR = ar
AS = as
RANLIB = ranlib

# Base configuration
MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
CURRENT_DIR := $(dir $(MKFILE_PATH))
INCLUDE_DIR := $(CURRENT_DIR)include
LIB_DIR := $(CURRENT_DIR)libs

KALDI_FLAVOR := dynamic
KALDILIBDIR := $(LIB_DIR)
DOUBLE_PRECISION = 0
OPENFSTINC = $(INCLUDE_DIR)/fst
OPENFSTLIBS = $(LIB_DIR)/libfst.so
OPENFSTLDFLAGS = -Wl,-rpath=$(LIB_DIR)

ATLASINC = $(INCLUDE_DIR)/ATLAS/include
ATLASLIBS = /usr/lib/libatlas.so.3 /usr/lib/libf77blas.so.3 /usr/lib/libcblas.so.3 /usr/lib/liblapack_atlas.so.3

# ATLAS specific Linux configuration

ifndef DOUBLE_PRECISION
$(error DOUBLE_PRECISION not defined.)
endif
ifndef OPENFSTINC
$(error OPENFSTINC not defined.)
endif
ifndef OPENFSTLIBS
$(error OPENFSTLIBS not defined.)
endif
ifndef ATLASINC
$(error ATLASINC not defined.)
endif
ifndef ATLASLIBS
$(error ATLASLIBS not defined.)
endif

# -I$(OPENFSTINC)
CXXFLAGS = -std=c++11 -I$(INCLUDE_DIR)/ $(EXTRA_CXXFLAGS) \
           -Wall -Wno-sign-compare -Wno-unused-local-typedefs \
           -Wno-deprecated-declarations -Winit-self \
           -DKALDI_DOUBLEPRECISION=$(DOUBLE_PRECISION) \
           -DHAVE_EXECINFO_H=1 -DHAVE_CXXABI_H -DHAVE_ATLAS -I$(ATLASINC) \
           -msse -msse2 -pthread \
           -g # -O0 -DKALDI_PARANOID

ifeq ($(KALDI_FLAVOR), dynamic)
CXXFLAGS += -fPIC
endif

# Compiler specific flags
COMPILER = $(shell $(CXX) -v 2>&1)
ifeq ($(findstring clang,$(COMPILER)),clang)
# Suppress annoying clang warnings that are perfectly valid per spec.
CXXFLAGS += -Wno-mismatched-tags
endif

LDFLAGS = $(EXTRA_LDFLAGS) $(OPENFSTLDFLAGS) $(ATLASLDFLAGS) -rdynamic
LDLIBS = $(EXTRA_LDLIBS) $(OPENFSTLIBS) $(ATLASLIBS) -lm -lpthread -ldl

# CUDA configuration

# CUDA = true
# CUDATKDIR = /usr/local/cuda
# CUDA_ARCH = -gencode arch=compute_20,code=sm_20 -gencode arch=compute_30,code=sm_30 -gencode arch=compute_35,code=sm_35 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_53,code=sm_53 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_61,code=sm_61 -gencode arch=compute_62,code=sm_62

# ifndef DOUBLE_PRECISION
# $(error DOUBLE_PRECISION not defined.)
# endif
# ifndef CUDATKDIR
# $(error CUDATKDIR not defined.)
# endif

# CUDA_INCLUDE= -I$(CUDATKDIR)/include
# CUDA_FLAGS = -g -Xcompiler -fPIC --verbose --machine 64 -DHAVE_CUDA \
#             -ccbin $(CXX) -DKALDI_DOUBLEPRECISION=$(DOUBLE_PRECISION)
# CXXFLAGS += -DHAVE_CUDA -I$(CUDATKDIR)/include
# CUDA_LDFLAGS += -L$(CUDATKDIR)/lib64 -Wl,-rpath,$(CUDATKDIR)/lib64
# CUDA_LDLIBS += -lcublas -lcusparse -lcudart -lcurand #LDLIBS : The libs are loaded later than static libs in implicit rule

# Environment configuration

