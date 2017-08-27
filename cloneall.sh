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
  cd $pkg
#  owner=$(basename $(dirname $url))
#  curl -s -H "Authorization: token $(cat ../../token)" \
#    -d '' https://api.github.com/repos/$owner/$pkg.jl/forks > /dev/null
#  git remote add mine https://${USER}@github.com/$USER/$pkg.jl || true
  cd ..
fi
}
clone_or_pull https://github.com/JuliaLang/METADATA.jl METADATA
for urlfile in $(ls METADATA/*/url); do
  clone_or_pull $(cat $urlfile) $(basename $(dirname $urlfile))
done

echo
echo
for urlfile in $(ls METADATA/*/url); do
  pkg=$(basename $(dirname $urlfile))
  cd $pkg
  git status | grep -q "up-to-date" || echo "$pkg not up-to-date"
  cd ..
done
