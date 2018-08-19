#!/usr/bin/env python
"""Setup configuration."""
from __future__ import print_function

import os
import subprocess
import sys

import distutils.command.build
import setuptools.command.build_ext
import setuptools.command.install_lib
import setuptools.command.test
import setuptools.extension

from distutils.file_util import copy_file
from setuptools import setup, find_packages, Command

def check_output(*args, **kwargs):
    return subprocess.check_output(*args, **kwargs).decode("utf-8").strip()

################################################################################
# Check variables / find programs
################################################################################

DEBUG = os.getenv('DEBUG', 'NO').upper() in ['ON', '1', 'YES', 'TRUE', 'Y']

CWD = os.path.dirname(os.path.abspath(__file__))
BUILD_DIR = os.path.join(CWD, 'build')


CLIF_LIB_DIR = os.path.join(CWD, "clif/python")
LIB_DIR = os.path.join(CWD, 'libs')
LIBS = [f.replace("lib","").replace(".so", "") for f in os.listdir(LIB_DIR)] #Remove lib and extension


KALDI_MK_PATH = os.path.join(CWD, "kaldi.mk")
if not os.path.isfile(KALDI_MK_PATH):
  print("\nCould not find kaldi.mk\n", file=sys.stderr)
  sys.exit(1)

with open("Makefile", "w") as makefile:
    print("include {}".format(KALDI_MK_PATH), file=makefile)
    print("print-% : ; @echo $($*)", file=makefile)
CXX_FLAGS = check_output(['make', 'print-CXXFLAGS'])
LD_FLAGS = check_output(['make', 'print-LDFLAGS'])
LD_LIBS = check_output(['make', 'print-LDLIBS'])


# TODO (VM): Support CUDA
CUDA = False
# CUDA = check_output(['make', 'print-CUDA']).upper() == 'TRUE'
if CUDA:
    CUDA_LD_FLAGS = check_output(['make', 'print-CUDA_LDFLAGS'])
    CUDA_LD_LIBS = check_output(['make', 'print-CUDA_LDLIBS'])
subprocess.check_call(["rm", "Makefile"])

TFRNNLM_LIB_PATH = os.path.join(CWD, "libs",
                                "libkaldi-tensorflow-rnnlm.so")
KALDI_TFRNNLM = True if os.path.exists(TFRNNLM_LIB_PATH) else False
if KALDI_TFRNNLM:
    with open("Makefile", "w") as makefile:
        TF_DIR = os.path.join(KALDI_DIR, "tools", "tensorflow")
        print("TENSORFLOW = {}".format(TF_DIR), file=makefile)
        TFRNNLM_MK_PATH = os.path.join(KALDI_DIR, "src", "tfrnnlm",
                                       "Makefile")
        for line in open(TFRNNLM_MK_PATH):
            if line.startswith("include") or line.startswith("TENSORFLOW"):
                continue
            print(line, file=makefile, end='')
        print("print-% : ; @echo $($*)", file=makefile)
    TFRNNLM_CXX_FLAGS = check_output(['make', 'print-EXTRA_CXXFLAGS'])
    TF_LIB_DIR = os.path.join(KALDI_DIR, "tools", "tensorflow",
                              "bazel-bin", "tensorflow")
    subprocess.check_call(["rm", "Makefile"])

MAKE_NUM_JOBS = os.getenv('MAKE_NUM_JOBS')
if not MAKE_NUM_JOBS:
    # This is the logic ninja uses to guess the number of parallel jobs.
    NPROC = int(check_output(['getconf', '_NPROCESSORS_ONLN']))
    if NPROC < 2:
        MAKE_NUM_JOBS = '2'
    elif NPROC == 2:
        MAKE_NUM_JOBS = '3'
    else:
        MAKE_NUM_JOBS = str(NPROC + 2)
MAKE_ARGS = ['-j', MAKE_NUM_JOBS]
try:
    import ninja
    CMAKE_GENERATOR = '-GNinja'
    MAKE = 'ninja'
    if DEBUG:
        MAKE_ARGS += ['-v']
except ImportError:
    CMAKE_GENERATOR = ''
    MAKE = 'make'
    if DEBUG:
        MAKE_ARGS += ['-d']


if DEBUG:
    print("#"*50)
    print("CWD:", CWD)
    print("CXX_FLAGS:", CXX_FLAGS)
    print("LD_FLAGS:", LD_FLAGS)
    print("LD_LIBS:", LD_LIBS)
    print("BUILD_DIR:", BUILD_DIR)
    print("CUDA:", CUDA)
    if CUDA:
        print("CUDA_LD_FLAGS:", CUDA_LD_FLAGS)
        print("CUDA_LD_LIBS:", CUDA_LD_LIBS)
    print("MAKE:", MAKE, *MAKE_ARGS)
    print("#"*50)
################################################################################
# Use CMake to build Python extensions in parallel
################################################################################
class Extension(setuptools.extension.Extension):
    """Dummy extension class that only holds the name of the extension."""
    def __init__(self, name):
        setuptools.extension.Extension.__init__(self, name, [])
        self._needs_stub = False
    def __str__(self):
        return "Extension({})".format(self.name)


def populate_extension_list():
    extensions = []
    lib_dir = os.path.join(BUILD_DIR, "lib")
    for dirpath, _, filenames in os.walk(os.path.join(lib_dir, "kaldi")):

        lib_path = os.path.relpath(dirpath, lib_dir)

        if lib_path == ".":
            lib_path = "kaldi"

        for f in filenames:
            r, e = os.path.splitext(f)
            if e == ".so":
                ext_name = "{}.{}".format(lib_path, r)
                extensions.append(Extension(ext_name))
    return extensions


class build(distutils.command.build.build):
    def finalize_options(self):
        self.build_base = 'build'
        self.build_lib = 'build/lib'
        distutils.command.build.build.finalize_options(self)


class build_ext(setuptools.command.build_ext.build_ext):
    def run(self):
        old_inplace, self.inplace = self.inplace, 0

        import numpy as np
        CMAKE_ARGS = ['-DCXX_FLAGS=' + CXX_FLAGS,
                      '-DLD_FLAGS=' + LD_FLAGS,
                      '-DLD_LIBS=' + LD_LIBS,
                      '-DNUMPY_INC_DIR='+ np.get_include(),
                      '-DCUDA=TRUE' if CUDA else '-DCUDA=FALSE',
                      '-DTFRNNLM=TRUE' if KALDI_TFRNNLM else '-DTFRNNLM=FALSE',
                      '-DDEBUG=TRUE' if DEBUG else '-DDEBUG=FALSE']


        if CUDA:
            CMAKE_ARGS +=['-DCUDA_LD_FLAGS=' + CUDA_LD_FLAGS,
                          '-DCUDA_LD_LIBS=' + CUDA_LD_LIBS]

        if KALDI_TFRNNLM:
            CMAKE_ARGS +=['-DTFRNNLM_CXX_FLAGS=' + TFRNNLM_CXX_FLAGS,
                          '-DTF_LIB_DIR=' + TF_LIB_DIR]

        if CMAKE_GENERATOR:
            CMAKE_ARGS += [CMAKE_GENERATOR]

        if DEBUG:
            CMAKE_ARGS += ['-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON']

        if not os.path.exists(BUILD_DIR):
            os.makedirs(BUILD_DIR)

        try:
            subprocess.check_call(['cmake', '..'] + CMAKE_ARGS, cwd = BUILD_DIR)
            subprocess.check_call([MAKE] + MAKE_ARGS, cwd = BUILD_DIR)
        except subprocess.CalledProcessError as err:
            # We catch this exception to disable stack trace.
            print(str(err), file=sys.stderr)
            sys.exit(1)
        print() # Add an empty line for cleaner output

        self.extensions = populate_extension_list()

        if DEBUG:
            for ext in self.extensions:
                print(ext)
            self.verbose = True

        self.inplace = old_inplace
        if old_inplace:
            self.copy_extensions_to_source()

    def get_ext_filename(self, fullname):
        """Convert the name of an extension (eg. "foo.bar") into the name
        of the file from which it will be loaded (eg. "foo/bar.so"). This
        patch overrides platform specific extension suffix with ".so".
        """
        ext_path = fullname.split('.')
        ext_suffix = '.so'
        return os.path.join(*ext_path) + ext_suffix

class install_lib(setuptools.command.install_lib.install_lib):
    def install(self):
        self.build_dir = 'build/lib'
        setuptools.command.install_lib.install_lib.install(self)

################################################################################
# Setup pykaldi
################################################################################

# We add a 'dummy' extension so that setuptools runs the build_ext step.
extensions = [Extension("kaldi")]

packages = find_packages(exclude=["tests.*", "tests"])

with open(os.path.join('kaldi', '__version__.py')) as f:
    exec(f.read())

setup(name = 'pykaldi',
      version = __version__,
      description = 'A Python wrapper for Kaldi',
      author = 'Dogan Can, Victor Martinez',
      ext_modules=extensions,
      cmdclass = {
          'build': build,
          'build_ext': build_ext,
          'install_lib': install_lib,
          },
      packages = packages,
      package_data = {},
      install_requires = ['enum34;python_version<"3.4"', 'numpy'],
      setup_requires=['pytest-runner'],
      tests_require=['pytest'],
      zip_safe = False,
      test_suite='tests')
