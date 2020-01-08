#!/bin/bash
REPO="sunway513/hiptensorflow:tf13-rocm172rc1-internal-v1"
cat password.txt | docker login --username svttestacc2018 --password-stdin
docker run -it  -v $HOME:/data --privileged --net=host --device="/dev/kfd" ${REPO}
