#!/bin/bash
echo "#Use Peng's latest docker image" > Dockerfile
echo "FROM $1" >> Dockerfile

echo "#Set working directory" >> Dockerfile
echo "WORKDIR /root/caffe2/caffe2/python" >> Dockerfile

echo "#Add scripts" >> Dockerfile
echo "ADD ./execs/c2ffe_exec.sh /root/caffe2/caffe2/python" >> Dockerfile
echo "ADD ./gpu_stats.log /root/caffe2/caffe2/python" >> Dockerfile

echo "#Set Caffe env vars" >> Dockerfile
echo "ENV MODEL $2" >> Dockerfile
echo "ENV NUM_GPUS $3" >> Dockerfile
echo "ENV BATCH_SIZE $4" >> Dockerfile
echo "ENV ITERATIONS $5" >> Dockerfile
echo "ENV LOOPS $6" >> Dockerfile
echo "ENV VERSION $7" >> Dockerfile
echo 'CMD ["./c2ffe_exec.sh"]' >> Dockerfile

