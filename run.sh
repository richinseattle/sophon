#!/bin/bash

docker build -t sophon-builder -f dockers/amd64-linux-musl/Dockerfile .
docker run --rm -ti -v $(pwd):/sophon --workdir /sophon sophon-builder ./util/build.sh
docker run --rm -ti -v $(pwd):/sophon --workdir /sophon sophon-builder ./util/clean.sh