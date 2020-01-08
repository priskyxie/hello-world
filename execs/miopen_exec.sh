#!/bin/bash

# copy over docker topology
WORKING_DIR=/results
${WORKING_DIR}/fetch_info_runtime_fw.sh > docker_runtime_fw_info.log

mi_start="./MIOpenDriver conv -i ${i} -t ${t} -V ${V} -F ${F} -s ${s} -H ${H} -W ${W} -n ${n} -c ${c} -k ${k} -y ${y} -x ${x} -p ${p} -q ${q} -u ${u} -v ${v}"

VER=( $(eval "dpkg -l | grep -i miopen") )
VER=${VER[2]}

echo -e "GPUs requested: ${GPU_COUNT}\n\
$(cat gpu_stats.log)\n\
\n\
MIOpen Version: ${VER}\n\
Test Loops: ${LOOPS}\n\
\n" | tee -a ${WORKING_DIR}/miopen_log.log

sleep 0.5

for (( n=1; n<=${LOOPS}; n++ ))
do
	START=$(date '+%s')
	echo -e "\n\n======================= Starting Training ${n}/${LOOPS} [$(date '+%d-%m-%Y %H:%M:%S')] =======================" | tee -a ${WORKING_DIR}/miopen_log.log

	for (( m=0; m<${GPU_COUNT}; m++ ))
	do
		echo "HIP_VISIBLE_DEVICES=${m} ${mi_start}" >> ${WORKING_DIR}/miopen_log.log
		eval "HIP_VISIBLE_DEVICES=${m} ${mi_start} 2>&1 | tee -a ${WORKING_DIR}/miopen_log.log &"
		pids[${m}]=$!
	done

	# wait for all pids
	for pid in ${pids[*]}
	do
		wait $pid
	done

	echo -e "\n\n======================= Finished Training ${n}/${LOOPS} [$(date '+%d-%m-%Y %H:%M:%S')] =======================" | tee -a ${WORKING_DIR}/miopen_log.log
	echo "duration $(($(date '+%s')-START)) seconds" | tee -a ${WORKING_DIR}/miopen_log.log

done
