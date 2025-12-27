#!/bin/bash
set -e

# Arguments
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

# Check if file exists
if [ ! -f "${FILE_NAME}.pas" ]; then
    echo "Error: ${FILE_NAME}.pas not found in $(pwd)"
    exit 1
fi

echo "--- Compiling ${FILE_NAME}.pas ---"

# 1. Run Mad Pascal
# CHANGE: Added -ipath:/opt/MadPascal/blibs so it can find B_CRT
# CHANGE: Added -ipath:/code so it can find local units if needed
mp "${FILE_NAME}.pas" \
   -ipath:/code \
   -ipath:/opt/MadPascal/base \
   -ipath:/opt/MadPascal/lib \
   -ipath:/opt/MadPascal/blibs \
   -o

# 2. Run Mad Assembler
# CHANGE: Added -i:/opt/MadPascal/blibs to MADS includes just in case
mads "${FILE_NAME}.a65" -x -i:/opt/MadPascal/base -i:/opt/MadPascal/blibs -o:"${FILE_NAME}.xex"

echo "--- Build Successful: ${FILE_NAME}.xex ---"
ls -l "${FILE_NAME}.xex"
