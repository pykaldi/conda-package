#!/usr/bin/env python
"""Setup configuration."""
import os
from setuptools import setup, Extension

CWD = os.path.dirname(os.path.abspath(__file__))
CLIF_DIR = os.path.join(CWD, "clif/python")
LIBS = os.path.join(CWD, 'libs')

def _extension_list():
    """Return list with Extensions for each .cc and _init.cc files in kaldi directory"""
    extensions = []
    for dirpath, _, filenames in os.walk(os.path.join(CWD, "kaldi")):
        for f in filenames:
            r, e = os.path.splitext(f)
            if e == ".cc" and not r.endswith('-init'):
                ext = Extension(r, [
                            '{}/{}.cc'.format(dirpath, r),
                            '{}/{}-init.cc'.format(dirpath, r),
                            os.path.join(CLIF_DIR, 'runtime.cc'),
                            os.path.join(CLIF_DIR, 'slots.cc'),
                            os.path.join(CLIF_DIR, 'types.cc'),
                        ],
                        include_dirs = [
                            CWD,
                            os.path.join(CWD, "kaldi"),
                            os.path.join(CWD, "openfst"),
                            os.path.join(CLIF_DIR),
                        ],
                        extra_compile_args = ['-std=c++11'],
                        library_dirs = [CWD, LIBS],
                        libraries = os.listdir(LIBS))
                extensions.append(ext)
    return extensions

################################################################################
# Setup pykaldi
################################################################################
with open(os.path.join('kaldi', '__version__.py')) as f:
    exec(f.read())

setup(name = 'pykaldi',
      version = __version__,
      description = 'A Python wrapper for Kaldi',
      author = 'Dogan Can, Victor Martinez',
      install_requires = ['enum34;python_version<"3.4"', 'numpy'],
      ext_modules = _extension_list(),
      zip_safe = False)
