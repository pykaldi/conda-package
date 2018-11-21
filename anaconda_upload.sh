#!/bin/bash
PKG_NAME=Pykaldi
USER=Pykaldi
BLD_PATH=/usr/local/conda-bld/linux-64/

conda build $1
for f in $(find $BLD_PATH -type f -name "*.tar.bz2"); do
	anaconda -t $CONDA_UPLOAD_TOKEN upload -u $USER $f
done
