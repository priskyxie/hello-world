#!/bin/bash
REPO="sunway513/hipcaffe:rocm1.7.1-rc8"
cat password.txt | docker login --username svttestacc2018 --password-stdin
docker run -it  -v $HOME:/data --privileged --net=host --device="/dev/kfd" ${REPO}
