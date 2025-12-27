#!/bin/bash
set -e

FILE_NAME=$1
MODE=$2

if [ -z "$FILE_NAME" ] || [ "$MODE" == "0" ]; then
    echo "--- Interactive Mode ---"
    exec tail -f /dev/null
fi

cd /code

if [ ! -f "${FILE_NAME}.pas" ]; then
    echo "Error: ${FILE_NAME}.pas not found in $(pwd)"
    exit 1
fi

echo "--- Compiling ${FILE_NAME}.pas ---"

# 1. Run Mad Pascal
mp "${FILE_NAME}.pas" \
   -ipath:/code \
   -ipath:/opt/MadPascal/base \
   -ipath:/opt/MadPascal/lib \
   -ipath:/opt/MadPascal/blibs \
   -o

# 2. Run Mad Assembler
# Note: Added -i for blibs so MADS can find included .asm files
mads "${FILE_NAME}.a65" \
     -x \
     -i:/opt/MadPascal/base \
     -i:/opt/MadPascal/blibs \
     -o:"${FILE_NAME}.xex"

echo "--- Build Successful: ${FILE_NAME}.xex ---"
ls -l "${FILE_NAME}.xex"
