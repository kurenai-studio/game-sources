#!/usr/bin/env bash

cd "$(dirname "$0")"
rm -rf out
mkdir out
cd src
zip -r ../out/lanve2d.love .