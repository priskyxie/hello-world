#!/bin/bash

# copy over docker topology
WORKING_DIR=/results
PD=${PWD}
cd ${WORKING_DIR}

./fetch_info_runtime_fw.sh > docker_runtime_fw_info.log

TENSOR_VER=$(python${VERSION} -c "import tensorflow as tf; print (tf.__version__)")

# get correct python
((${VERSION} > 2)) && echo "== Requested Version 3 =="

DATA_SYNTAX=""
if [ ${DATASET} == 'imagenet' ]; then
	DATA_SYNTAX="--data_name=imagenet --data_dir=/realdata "
elif [ ${DATASET} == 'cifar10' ]; then
	DATA_SYNTAX="--data_name=cifar10 --data_dir=/realdata "
else
	DATASET="none"
fi

tensor_start="python${VERSION} /root/benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --model=${TF_BM_MODEL} ${DATA_SYNTAX}\
--train_dir=${WORKING_DIR} --save_summaries_steps 10 --save_model_secs=3600 --print_training_accuracy=True \
--num_batches=${TF_BM_NUM_BATCHES} --num_gpus=${TF_BM_NUM_GPUS} \
--batch_size=${TF_BM_BATCH_SIZE} 2>&1 | tee -a ${WORKING_DIR}/tensor_log.log"

echo -e "GPUs requested: ${TF_BM_NUM_GPUS}\n\
$(cat ${PD}/gpu_stats.log)\n\
\n\
Benchmark GitHub Hash: ${benchmark_hash}\n\
Tensorflow Version: ${TENSOR_VER}\n\
\n\
Model: ${TF_BM_MODEL}\n\
DataSet: ${DATASET}\n\
\n\
Batch Size: ${TF_BM_BATCH_SIZE}\n\
Batches: ${TF_BM_NUM_BATCHES}\n\
Test Loops: ${TF_BM_LOOPS}\n\
\n\
Tensor Command: ${tensor_start}\n" | tee -a ${WORKING_DIR}/tensor_log.log
sleep 1

export TF_ROCM_FUSION_ENABLE=1

for i in `seq 1 ${TF_BM_LOOPS}`
do
	START=$(date '+%s')
	echo -e "\n\n======================= Starting Training $i/${TF_BM_LOOPS} [$(date '+%d-%m-%Y %H:%M:%S')] =======================" | tee -a ${WORKING_DIR}/tensor_log.log
	eval "${tensor_start}"
	echo -e "\n\n======================= Finished Training $i/${TF_BM_LOOPS} [$(date '+%d-%m-%Y %H:%M:%S')] =======================" | tee -a ${WORKING_DIR}/tensor_log.log
	echo "duration $(($(date '+%s')-START)) seconds" | tee -a ${WORKING_DIR}/tensor_log.log
done
