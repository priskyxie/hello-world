#!/bin/bash


OUTPUT_DIR=/results

# copy over docker topology
#${OUTPUT_DIR}/fetch_info_runtime_fw.sh > ${OUTPUT_DIR}/docker_runtime_fw_info.log

DATA_SYNTAX="null"
if [ ${DATASET_FLAG} == 'imagenet' ]; then
	DATA_SYNTAX="/data/resnet_trainer/imagenet_cars_boats_train/"
fi

#caffe2_start="python /root/caffe2/build/caffe2/python/examples/imagenet_trainer.py --train_data ${DATA_SYNTAX} --num_epochs ${NUM_EPOCH} --epoch_size ${EPOCH_SIZE} --batch_size ${BATCH_SIZE} --num_gpus ${NUM_GPUS} 2>&1 | tee -a ${OUTPUT_DIR}/c2ffe_log.log"
caffe2_start="/usr/bin/python3.6 convnet_benchmarks.py --model ${MODEL} --batch_size ${BATCH_SIZE} --iterations ${ITERATIONS} 2>&1|tee -a ${OUTPUT_DIR}/c2ffe_log.log"

echo -e "$(cat gpu_stats.log)\n\n\
GPUs requested: ${NUM_GPUS}\n\
Model: ${MODEL}\n\
#Epoch Count: ${NUM_EPOCH}\n\
#Epoch Size: ${EPOCH_SIZE}\n\
Batch Size: ${BATCH_SIZE}\n\
Iteraions: ${ITERATIONS}\n\
Test Loops: ${LOOPS}\n\n\
Caffe2 Command: ${caffe2_start}\n" | tee -a ${OUTPUT_DIR}/c2ffe_log.log

for i in `seq 1 ${LOOPS}`
do
	START=$(date '+%s')
	echo -e "\n\n======================= Starting Caffe $i/${LOOPS} [$(date '+%d-%m-%Y %H:%M:%S')] =======================" | tee -a ${OUTPUT_DIR}/c2ffe_log.log

        eval "${caffe2_start}"	
	echo -e "\n\n======================= Finished Training $i/${LOOPS} [$(date '+%d-%m-%Y %H:%M:%S')] =======================" | tee -a ${OUTPUT_DIR}/c2ffe_log.log
	echo "duration $(($(date '+%s')-START)) seconds" | tee -a ${OUTPUT_DIR}/c2ffe_log.log
done
