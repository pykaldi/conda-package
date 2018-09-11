export CFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib"
export CPATH=${PREFIX}/include
export PYCLIF="/home/victor/miniconda3/bin/pyclif"
export CLIF_MATCHER="/home/victor/miniconda3/clang/bin/clif-matcher"
export LD_LIBRARY_PATH="/home/victor/miniconda3/lib/:${LD_LIBRARY_PATH}"

# Install kaldi locally
cd "$SRC_DIR/tools"
#./install_protobuf.sh
#./install_clif.sh
./install_kaldi.sh

# Python command to install pykaldi
cd "$SRC_DIR"
$PYTHON setup.py install

##########################################################################
# Update pykaldi RPATHs to include $ORIGIN, pykaldi, kaldi/lib, and conda lib
##########################################################################
# Create lib folder
mkdir -p $SP_DIR/kaldi/lib

# Create an rpath string from a list of all pykaldi sub-packages
rpath="\$ORIGIN/.."
find $SP_DIR/kaldi -maxdepth 1 -type d -exec basename {} \; | while read pkg; do
	if [[ $pkg -ne "__pycache__" ]] && [[ $pkg -ne "kaldi" ]]; then
		rpath=rpath":\$ORIGIN/../$pkg"
	fi
done

# Update so files
find $SP_DIR/kaldi -name "*.so" -type f | while read sofile; do
	echo "Setting rpath of $sofile to \$ORIGIN, pykaldi rpath, kaldi/lib, conda/lib"
	patchelf --set-rpath "$rpath:\$ORIGIN/../lib:\$ORIGIN/../../../.." $sofile
done

#####################################
# Update kaldi rpaths
#####################################
# Kaldi libraries
cp $SRC_DIR/tools/kaldi/src/lib/*.so $SP_DIR/kaldi/lib

# Openfst libraries (copy links and files)
rsync --links $SRC_DIR/tools/kaldi/tools/openfst/lib/ $SP_DIR/kaldi/lib/

# Update lib so files
find $SP_DIR/kaldi/lib -maxdepth 1 -name "*.so" -type f | while read sofile; do
	echo "Setting rpath of $sofile to \$ORIGIN, conda/lib"
	patchelf --set-rpath '$ORIGIN:$ORIGIN/../../../..' $sofile
done
