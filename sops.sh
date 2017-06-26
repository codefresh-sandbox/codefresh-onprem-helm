#!/bin/sh

# read input parameters
while [ $# -gt 0 ]
do
  case "$1" in
    -d) enc="d"; flag="l"; shift;;
    -e) enc="e"; flag="L"; shift;;
    -h)
        echo >&2 "usage: $0 -(e|d) [encrypt|decrypt secret files]"
        exit 1;;
     *) break;; # terminate while loop
  esac
  shift
done

# get only encrypted or non encrypted files
for f in $(find . -name "*-secrets.yaml" -exec grep -$flag "arn:aws:kms:" {} +); do 
  echo "Processing $f file"
  sops -$enc -i $f
done