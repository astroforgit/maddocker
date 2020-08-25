#!/bin/bash
  if ![ -z "$1" ] tail -f /dev/null
  set -x
  cd /tmp
  export PATH="/madPascal:$PATH"
  export PATH="/paslib:$PATH"
  mp $1.pas -o
  mads $1.a65 -x -i:/madPascal/base -o:$1.xex
  ls
  #mads $1.a65 -x -o:$1.xex
