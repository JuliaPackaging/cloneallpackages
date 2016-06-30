#!/bin/sh
# clone/pull master of all registered packages
# useful to grep for julia code usage
clone_or_pull () {
set -e
url=$1
pkg=$2
if [ -e $pkg ]; then
  cd $pkg
  echo "$pkg $(git pull)"
  cd ..
else
  echo "$pkg $(git clone -q $url $pkg)"
fi
}
clone_or_pull https://github.com/JuliaLang/METADATA.jl METADATA
for urlfile in $(ls METADATA/*/url); do
  clone_or_pull $(cat $urlfile) $(basename $(dirname $urlfile))
done
