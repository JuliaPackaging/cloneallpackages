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
git push mine-oauth +$newbranch
git remote rm mine-oauth

#owner=$(basename $(dirname $(cat ../METADATA/$pkg/url)))
#curl -s -H "Authorization: token $(cat ../../token)" \
#  -d "{\"title\": \"$(echo $commitmsg | head -n1)\", \
#       \"body\": \"$(echo $commitmsg | tail -n+2)\", \
#       \"head\": \"$USER:$newbranch\", \
#       \"base\": \"$oldbranch\", \
#       \"maintainer_can_modify\": true}" \
#  https://api.github.com/repos/$owner/$pkg.jl/pulls | jq . #> /dev/null
# TODO: check if the response says invalid, fail loudly if that happens
#sleep 3 # avoid making the rate limit too mad

git checkout $oldbranch
#git show $newbranch | git apply
git branch -D $newbranch
cd ..
