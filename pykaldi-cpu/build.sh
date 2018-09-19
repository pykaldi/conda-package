set -x
export CFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib"
export CPATH=${PREFIX}/include
export PYCLIF="/home/victor/miniconda3/envs/pykaldi/bin/pyclif"
export CLIF_MATCHER="/home/victor/miniconda3/envs/pykaldi/clang/bin/clif-matcher"

# Create lib folder
LIB_FOLDER="$SP_DIR/kaldi/lib"
mkdir -p $LIB_FOLDER
	
#####################################
# Install kaldi locally
#####################################
cd "$SRC_DIR/tools"
./install_kaldi.sh

#####################################
# Copy and update kaldi rpaths
#####################################

# Kaldi libraries (copy files and links)
cp $SRC_DIR/tools/kaldi/src/lib/*.so* $LIB_FOLDER

# Openfst libraries (copy files and links)
cp -av $SRC_DIR/tools/kaldi/tools/openfst/lib/*.so* $LIB_FOLDER

# Update so files rpath to $ORIGIN and conda lib directory (relative to site-packages/kaldi/lib)
find $SP_DIR/kaldi/lib -maxdepth 1 -name "*.so*" -type f | while read sofile; do
	echo "Setting rpath of $sofile to \$ORIGIN, conda/lib"
	patchelf --set-rpath '$ORIGIN:$ORIGIN/../../../..' $sofile
done

##########################################################################
# install pykaldi
##########################################################################
cd "$SRC_DIR"
$PYTHON setup.py install
