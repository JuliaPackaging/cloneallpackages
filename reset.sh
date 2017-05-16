#!/bin/bash
for f in *; do (cd $f && git reset --hard origin/master); done
