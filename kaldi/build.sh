export CFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib"
export CPATH=${PREFIX}/include

set -x

cd "$SRC_DIR/tools"

# Prevent kaldi from switching default python version
mkdir -p "python"
touch "python/.use_default_python"

./extras/check_dependencies.sh

make -j4

cd ../src
./configure --shared 
make clean -j && make depend -j && make -j4

# Create links to libraries

echo "Done installing Kaldi."