#!/bin/sh

# read input parameters
while [ $# -gt 0 ]
do
  case "$1" in
    -d) dec=1; shift;;
    -e) enc=1; shift;;
    -h)
        echo >&2 "usage: $0 -(e|d) [encrypt|decrypt '*-enc.yaml' values files]"
        exit 1;;
     *) break;; # terminate while loop
  esac
  shift
done

# encrypt files
if [[ $enc -eq 1 ]]; then
  for f in $(find . -name "*-dec.yaml"); do 
    echo "Encrypting $f ..."
    sops -e $f > ${f/dec/enc}
  done
fi

# descrypt files
if [[ $dec -eq 1 ]]; then
  for f in $(find . -name "*-enc.yaml"); do 
    echo "Decrypting $f file"
    sops -d $f > ${f/enc/dec}
  done
fi