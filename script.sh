#!/bin/bash
set -e

# Arguments passed from Docker command
FILE_NAME=$1
MODE=$2

# =========================================================
# MODE 0: Interactive / Debug
# Keeps container running if no filename is provided 
# or if user explicitly passes '0' as second arg
# =========================================================
if [ -z "$FILE_NAME" ] || [ "$MODE" == "0" ]; then
    echo "--- Container is running in interactive mode ---"
    echo "You can run: mp <filename> or mads <filename>"
    exec tail -f /dev/null
fi

# =========================================================
# MODE 1: Compile (Default)
# =========================================================
cd /code

# 1. Check if file exists
if [ ! -f "${FILE_NAME}.pas" ]; then
    echo "Error: ${FILE_NAME}.pas not found in $(pwd)"
    exit 1
fi

echo "--- Compiling ${FILE_NAME}.pas ---"

# 2. Run Mad Pascal (Generates .a65 assembly file)
mp "${FILE_NAME}.pas" -o

# 3. Run Mad Assembler (Generates .xex binary)
# -x: Exclude unused symbols
# -i: Include path for base libraries
# -o: Output filename
mads "${FILE_NAME}.a65" -x -i:/opt/MadPascal/base -o:"${FILE_NAME}.xex"

echo "--- Build Successful: ${FILE_NAME}.xex ---"
ls -l "${FILE_NAME}.xex"
