#!/bin/sh
# make a new branch and push to your remote
set -e
pkg=$1
newbranch=$2
commitmsg=$3
cd $pkg
oldbranch=$(git rev-parse --abbrev-ref HEAD)
git checkout -b $newbranch
git add .
git commit -m "$commitmsg"
git remote add mine-oauth https://$(cat ../../token):x-oauth-basic@github.com/$USER/$pkg.jl
git push mine-oauth $newbranch
git remote rm mine-oauth
git checkout $oldbranch
cd ..
