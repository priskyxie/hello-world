#!/bin/bash
echo "#Use Peng's latest docker image" > Dockerfile
echo "FROM $1" >> Dockerfile

echo "#Set working directory" >> Dockerfile
echo "WORKDIR /root/hipCaffe" >> Dockerfile

echo "#Add scripts" >> Dockerfile
echo "ADD ./execs/caffe_exec.sh /root/hipCaffe" >> Dockerfile
echo "ADD ./gpu_stats.log /root/hipCaffe" >> Dockerfile

echo "#Set Caffe env vars" >> Dockerfile
echo "ENV BM_LOOPS $2" >> Dockerfile
echo "ENV BM_NUM_GPUS $3" >> Dockerfile

echo 'CMD ["./caffe_exec.sh"]' >> Dockerfile
