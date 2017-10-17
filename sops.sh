#!/bin/bash

# read input parameters
while [ $# -gt 0 ]
do
  case "$1" in
    -d) ACTION=DECRYPT; shift;;
    -e) ACTION=ENCRYPT; shift;;
    -h)
        echo >&2 "usage: $0 -(e|d) [encrypt|decrypt '*-enc.yaml' values files]"
        exit 1;;
     *) break;; # terminate while loop
  esac
done

DIR=${1:-$(dirname $0)}


# encrypt files
if [[ $ACTION == "ENCRYPT" ]]; then
  echo "Executing sops $ACTION on all *-dec.yaml files in directory $DIR "
  for f in $(find ${DIR} -name "*-dec.yaml"); do
    echo "Encrypting $f ..."
    sops -e $f > ${f/-dec.yaml/-enc.yaml}
  done
fi

# descrypt files
if [[ $ACTION == "DECRYPT" ]]; then
  echo "Executing sops $ACTION on all *-enc.yaml files in directory $DIR "
  for f in $(find ${DIR} -name "*-enc.yaml"); do
    echo "Decrypting $f file"
    sops -d $f > ${f/-enc.yaml/-dec.yaml}
  done
fi
