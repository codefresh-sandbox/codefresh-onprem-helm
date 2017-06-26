#!/bin/sh

# read input parameters
while [ $# -gt 0 ]
do
  case "$1" in
    -d) enc="-d"; shift;;
    -e) enc="-e"; shift;;
    -h)
        echo >&2 "usage: $0 -[(e|d) - encrypt|decrypt]"
        exit 1;;
     *) break;; # terminate while loop
  esac
  shift
done

for f in $(find . -name "*-secrets.yaml"); do 
  echo "Processing $f file"
  sops $enc -i $f
done