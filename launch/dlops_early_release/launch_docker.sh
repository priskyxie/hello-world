#!/bin/bash
REPO="hiptensorflow:rocm1.9.1-tf1.10-resnet50-fp16-v2"
cat password.txt | docker login --username svttestacc2018 --password-stdin
# pull image if it doesn't exist locally
if [[ "$(docker images -q ${REPO} 2> /dev/null)" == "" ]]; then
	echo "Pulling image ${REPO} ... "
	docker pull ${REPOSITORY}
fi
docker run -it  -v $HOME:/data --privileged --net=host --device="/dev/kfd" ${REPO}
