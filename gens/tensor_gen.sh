#!/bin/bash
echo "#Use Peng's latest docker image" > Dockerfile
echo "FROM $1" >> Dockerfile

echo "#Set working directory" >> Dockerfile
echo "WORKDIR /root/benchmarks/scripts/tf_cnn_benchmarks" >> Dockerfile

echo "#Add scripts" >> Dockerfile
echo "ADD ./execs/tensor_exec.sh /root/benchmarks/scripts/tf_cnn_benchmarks" >> Dockerfile
echo "ADD ./gpu_stats.log /root/benchmarks/scripts/tf_cnn_benchmarks" >> Dockerfile
echo "#Set TF Benchmark env vars" >> Dockerfile
echo "ENV TF_BM_MODEL $2" >> Dockerfile
echo "ENV TF_BM_NUM_GPUS $3" >> Dockerfile
echo "ENV TF_BM_BATCH_SIZE $4" >> Dockerfile
echo "ENV TF_BM_NUM_BATCHES $5" >> Dockerfile
echo "ENV TF_BM_LOOPS $6" >> Dockerfile
echo "ENV VERSION $7" >> Dockerfile
echo "ENV DATASET $8" >> Dockerfile
echo 'CMD ["./tensor_exec.sh"]' >> Dockerfile
