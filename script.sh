#!/bin/bash
set -e

FILE_NAME=$1
MODE=$2

# =========================================================
# MODE 0: Interactive / Debug
# =========================================================
if [ -z "$FILE_NAME" ] || [ "$MODE" == "0" ]; then
    echo "--- Container is running in interactive mode ---"
    exec tail -f /dev/null
fi

# =========================================================
# MODE 1: Compile
# =========================================================
cd /code

if [ ! -f "${FILE_NAME}.pas" ]; then
    echo "Error: ${FILE_NAME}.pas not found in $(pwd)"
    exit 1
fi

echo "--- Compiling ${FILE_NAME}.pas ---"

# 1. Run Mad Pascal
# WE ADDED: -ipath:/opt/MadPascal/blibs so it can find b_crt
mp "${FILE_NAME}.pas" \
   -ipath:/code \
   -ipath:/opt/MadPascal/base \
   -ipath:/opt/MadPascal/lib \
   -ipath:/opt/MadPascal/blibs \
   -o

# 2. Run Mad Assembler
mads "${FILE_NAME}.a65" -x -i:/opt/MadPascal/base -o:"${FILE_NAME}.xex"

echo "--- Build Successful: ${FILE_NAME}.xex ---"
ls -l "${FILE_NAME}.xex"
