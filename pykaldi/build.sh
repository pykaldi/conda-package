export CFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib"
export CPATH=${PREFIX}/include
export PYCLIF="/home/victor/miniconda3/bin/pyclif"
export CLIF_MATCHER="/home/victor/miniconda3/clang/bin/clif-matcher"
export LD_LIBRARY_PATH="/home/dogan/tools/protobuf/lib:${LD_LIBRARY_PATH}"

# Install kaldi locally
cd "$SRC_DIR/tools"
./install_protobuf.sh
./install_clif.sh
./install_kaldi.sh

# Python command to install pykaldi
cd "$SRC_DIR"
python setup.py install --single-version-externally-managed --record=record.txt 

#####################################
# Copy kaldi libs and update pykaldi
#####################################
mkdir -p $SP_DIR/lib

# Kaldi libraries
cp $SRC_DIR/tools/kaldi/lib/*.so $SP_DIR/lib

# Openfst libraries
cp $SRC_DIR/tools/kaldi/tools/openfst/lib/*.so $SP_DIR/lib

# From: https://github.com/pytorch/builder/blob/master/conda/pytorch-0.4.1/build.sh
# Update RPATHs with patched names
# find $SP_DIR/kaldi -name "*.so*" | while read sofile; do
# 	origname=${???}
# 	patchedname=${???}
# 	set +e
# 	patchelf --print-needed $sofile | grep $origname 2>&1 >/dev/null
# 	ERRCODE=$?
# 	set -e
# 	if [ "$ERRCODE" -eq "0" ]; then
# 		echo "Patching $sofile entry $origname to $patchedname"
# 		patchelf --replace-needed $origname $patchedname $sofile
# 	fi
# done

# set RPATH of _C.so and similar to $ORIGIN, $ORIGIN/lib and conda/lib
find $SP_DIR/kaldi -name "*.so*" -maxdepth 1 -type f | while read sofile; do
	echo "Setting rpath of $sofile to " '$ORIGIN:$ORIGIN/lib:$ORIGIN/../../..'
	patchelf --set-rpath '$ORIGIN:$ORIGIN/../lib:$ORIGIN/../../..' $sofile
	patchelf --print-rpath $sofile
done

# set RPATH of lib/ files to $ORIGIN and conda/lib
find $SP_DIR/kaldi/lib -name "*.so*" -maxdepth 1 -type f | while read sofile; do
	echo "Setting rpath of $sofile to " '$ORIGIN:$ORIGIN/../../../..'
	patchelf --set-rpath '$ORIGIN:$ORIGIN/../../../..' $sofile
	patchelf --print-rpath $sofile
done
