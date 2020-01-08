#!/bin/bash
echo "#Use Peng's latest docker image" > Dockerfile
echo "FROM $1" >> Dockerfile

echo "#Set working directory" >> Dockerfile
echo "WORKDIR /root/pytorch/test/" >> Dockerfile

echo "#Add scripts" >> Dockerfile
echo "ADD ./execs/pytorch_exec.sh /root/pytorch/test/" >> Dockerfile
echo "ADD ./gpu_stats.log /root/pytorch/test/" >> Dockerfile

echo "#Set Pytorch env vars" >> Dockerfile
echo "ENV NETWORK $2" >> Dockerfile
echo "ENV BATCH_SIZE $3" >> Dockerfile
echo "ENV ITERATIONS $4" >> Dockerfile
echo "ENV FP16 $5" >>Dockerfile
echo "ENV LOOPS $6" >> Dockerfile
echo 'CMD ["./pytorch_exec.sh"]' >> Dockerfile

