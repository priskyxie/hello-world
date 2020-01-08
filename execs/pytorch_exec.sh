#!/bin/bash

OUTPUT_DIR=/results

# copy over docker topology
#${OUTPUT_DIR}/fetch_info_runtime_fw.sh > ${OUTPUT_DIR}/docker_runtime_fw_info.log

#DATA_SYNTAX="null"
#if [ ${DATASET_FLAG} == 'imagenet' ]; then
#	DATA_SYNTAX="/data/resnet_trainer/imagenet_cars_boats_train/"
#fi

if [ ${FP16} == "none" ]; then
    pytorch_start="/usr/bin/python3.6 micro_benchmarking_pytorch.py --network ${NETWORK} --batch-size ${BATCH_SIZE} --iterations ${ITERATIONS} 2>&1|tee -a ${OUTPUT_DIR}/pytorch_log.log"
else
    pytorch_start="/usr/bin/python3.6 micro_benchmarking_pytorch.py --network ${NETWORK} --batch-size ${BATCH_SIZE} --iterations ${ITERATIONS} --fp16 ${FP16} 2>&1|tee -a ${OUTPUT_DIR}/pytorch_log.log"
fi

echo -e "$(cat gpu_stats.log)\n\n\
GPUs requested: ${NUM_GPUS}\n\
NetWork: ${NETWORK}\n\
Batch Size: ${BATCH_SIZE}\n\
Iterations: ${ITERATIONS}\n\
FP16: ${FP16}\n\
Loops: ${LOOPS}\n\
Pytorch Command: ${pytorch_start}\n" | tee -a ${OUTPUT_DIR}/pytorch_log.log

for i in `seq 1 ${LOOPS}`
do
	START=$(date '+%s')
	echo -e "\n\n======================= Starting Pytorch $i/${LOOPS} [$(date '+%d-%m-%Y %H:%M:%S')] =======================" | tee -a ${OUTPUT_DIR}/pytorch_log.log

        eval "${pytorch_start}"	
	echo -e "\n\n======================= Finished Training $i/${LOOPS} [$(date '+%d-%m-%Y %H:%M:%S')] =======================" | tee -a ${OUTPUT_DIR}/pytorch_log.log
	echo "duration $(($(date '+%s')-START)) seconds" | tee -a ${OUTPUT_DIR}/pytorch_log.log
done
