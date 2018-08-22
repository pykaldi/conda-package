cp $SRC_DIR/pykaldi/libs/* $PREFIX/lib/
$PYTHON setup.py install --single-version-externally-managed --record=record.txt  # Python command to install the script.
