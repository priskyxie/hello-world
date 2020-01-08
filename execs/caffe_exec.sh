#!/bin/bash

OUTPUT_DIR=/results
WORKING_DIR=/root/hipCaffe
PD=${PWD}
cd ${OUTPUT_DIR}

# copy over docker topology
./fetch_info_runtime_fw.sh > docker_runtime_fw_info.log

echo "Running MNIST, Cifar10 and CaffeNet Inference for ${BM_LOOPS} loops ... "
sleep 1

# Build MNIST and CIFAR10
cd ${WORKING_DIR}
./data/mnist/get_mnist.sh | tee -a ${OUTPUT_DIR}/caffe_log.log
./examples/mnist/create_mnist.sh | tee -a ${OUTPUT_DIR}/caffe_log.log

./data/cifar10/get_cifar10.sh | tee -a ${OUTPUT_DIR}/caffe_log.log
./examples/cifar10/create_cifar10.sh | tee -a ${OUTPUT_DIR}/caffe_log.log

# Build Soumith Benchmarks
git clone https://github.com/soumith/convnet-benchmarks

echo -e "GPUs Detected: ${BM_NUM_GPUS}\n\
$(cat ${PD}/gpu_stats.log)\n\
Test Loops: ${BM_LOOPS}" | tee -a ${OUTPUT_DIR}/caffe_log.log

for i in `seq 1 ${BM_LOOPS}`
do
	START=$(date '+%s')
	echo -e "\n\n======================= Starting Caffe $i/${BM_LOOPS} [$(date '+%d-%m-%Y %H:%M:%S')] =======================" | tee -a ${OUTPUT_DIR}/caffe_log.log

	echo -e "\n\n[$(date '+%d-%m-%Y %H:%M:%S')] Running MNIST. Saving to mnist_results.log" | tee -a ${OUTPUT_DIR}/caffe_log.log
	./build/tools/caffe -gpu all train --solver=examples/mnist/lenet_solver.prototxt 2>&1 | tee -a ${OUTPUT_DIR}/mnist_results.log

	echo -e "\n\n[$(date '+%d-%m-%Y %H:%M:%S')] Running Cifar10. Saving to cifar10_results.log" | tee -a ${OUTPUT_DIR}/caffe_log.log
	./build/tools/caffe -gpu all train --solver=examples/cifar10/cifar10_quick_solver.prototxt 2>&1 | tee -a ${OUTPUT_DIR}/cifar10_results.log

	echo -e "\n\n[$(date '+%d-%m-%Y %H:%M:%S')] Running Soumith Performance. Saving to *perf_results.log..." | tee -a ${OUTPUT_DIR}/caffe_log.log
	./build/tools/caffe -gpu all time --model=convnet-benchmarks/caffe/imagenet_winners/alexnet.prototxt 2>&1 | tee -a ${OUTPUT_DIR}/alexnet_perf_results.log
	./build/tools/caffe -gpu all time --model=convnet-benchmarks/caffe/imagenet_winners/googlenet.prototxt 2>&1 | tee -a ${OUTPUT_DIR}/googlenet_perf_results.log
	./build/tools/caffe -gpu all time --model=convnet-benchmarks/caffe/imagenet_winners/overfeat.prototxt 2>&1 | tee -a ${OUTPUT_DIR}/overfeat_perf_results.log
	./build/tools/caffe -gpu all time --model=convnet-benchmarks/caffe/imagenet_winners/vgg_a.prototxt 2>&1 | tee -a ${OUTPUT_DIR}/vgga_perf_results.log

	echo -e "\n\n======================= Finished Training $i/${BM_LOOPS} [$(date '+%d-%m-%Y %H:%M:%S')] =======================" | tee -a ${OUTPUT_DIR}/caffe_log.log
	echo "duration $(($(date '+%s')-START)) seconds" | tee -a ${OUTPUT_DIR}/caffe_log.log
done
