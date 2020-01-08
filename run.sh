#!/bin/bash

# Copy MI100 atitool to SnakeBytes since the original atitool in SnakeByetes doesn't support MI100
if [ ! -d "/root/SnakeBytes/lib/get_tools/atitool" ]; then
   mkdir /root/SnakeBytes/lib/get_tools/atitool
fi
if [ ! -f "/root/tools/atitool/atitool" ]; then
    echo "Start download MI100 tools..."
    ruby /root/storage/toolsupdater_mi100.rb
	cp /root/tools/atitool/atitool /root/SnakeBytes/lib/get_tools/atitool/
else
    cp /root/tools/atitool/atitool /root/SnakeBytes/lib/get_tools/atitool/	
fi
chmod +x /root/SnakeBytes/lib/get_tools/atitool/atitool
# mode specific configuration files
cd $docker

CONFIG_PATH=config
CONFIG_FILE_TF=tensor_config.csv
CONFIG_FILE_CF=caffe_config.csv
CONFIG_FILE_C2=c2ffe_config.csv
CONFIG_FILE_MI=miopen_config.csv
CONFIG_FILE_PY=pytorch_config.csv

# decide which framework to run based on this switch before reading test cases
if [ $# -gt 0 ] && [ $1 == '--caffe' ]; then
	CONFIG_FULL=${CONFIG_PATH}/${CONFIG_FILE_CF}
	RUNMODE='cf1'
elif [ $# -gt 0 ] && [ $1 == '--caffe2' ]; then
	CONFIG_FULL=${CONFIG_PATH}/${CONFIG_FILE_C2}
	RUNMODE='cf2'
elif [ $# -gt 0 ] && [ $1 == '--mi' ]; then
	CONFIG_FULL=${CONFIG_PATH}/${CONFIG_FILE_MI}
	RUNMODE='mi'
elif [ $# -gt 0 ] && [ $1 == '--pytorch' ]; then
	CONFIG_FULL=${CONFIG_PATH}/${CONFIG_FILE_PY}
	RUNMODE='py'	
else
	CONFIG_FULL=${CONFIG_PATH}/${CONFIG_FILE_TF}
	IMAGENET_DATA=$($docker/pys/readcfg.py "${CONFIG_FULL}" 'imagenet')
	CIPHER_DATA=$($docker/pys/readcfg.py "${CONFIG_FULL}" 'cifar')
	RUNMODE='tf'
fi

# assign common parameters between all 3 mode of operations
VERSION=$($docker/pys/readcfg.py "${CONFIG_FULL}" 'python')
REPOSITORY=$($docker/pys/readcfg.py "${CONFIG_FULL}" 'repo')
TESTLOOP=$($docker/pys/readcfg.py "${CONFIG_FULL}" 'loopall')
ATIREZ=$($docker/pys/readcfg.py "${CONFIG_FULL}" 'atirez')
NUM_DEVICES=$( cd ../get_tools; python -c "import atitool_lib; atitool_lib.get_num_gpus()" )
GENGRAPHS=0

# Reset function to reset config files
function reset_config ()
{
	if [ "${RUNMODE}" == "cf1" ]; then
		echo -e "\n\nWARNING: Restoring config file for caffe\n\n"
		echo -e "python,2\nrepo,sunway513/hipcaffe:rocm1.8.2-rc5-v1\nloopall,1\natirez,1000" > ${CONFIG_FULL}
	elif [ "${RUNMODE}" == "cf2" ]; then
		echo -e "\n\nWARNING: Restoring config file for caffe2 for Vega20\n\n"
		echo -e "python,2\nrepo,petrex/pytorch_rocm:512Vega20\nloopall,1\natirez,1000" > ${CONFIG_FULL}
	else
		echo -e "\n\nWARNING: Resetting config file and adding one default test case: googlenet,none,64,10000,1\n\n"
		echo -e "python,3\nrepo,rocm/tensorflow:latest\nimagnet,/tensor/imag\ncifar,/tensor/cifa\nloopall,1\natirez,1000\n#model,dataset,batchsize,batches,loops\ngooglenet,none,64,10000,1" > ${CONFIG_FULL}
	fi
}

# Clean system from docker containers but do not remove the images
function docker_clean ()
{
	echo -e "\n** stopping and cleaning all docker files (images are still intact) **\n"
	docker stop $(docker ps -a -q) # stop all running dockers
	docker rm $(docker ps -a -q) # destroy all dockers
	docker system prune -f
}

# Login to docker
function docker_login ()
{
	echo "Logging into Docker ... "
	cat password.txt | docker login --username svttestacc2018 --password-stdin
}

if ( [[ "$1" != --mi* && $# -gt 0 ]] && [[ "$1" != --caffe* && $# -gt 0 ]] && [[ "$1" != --pytorch && $# -gt 0 ]] ) || [[ "$1" != --mi && $# -gt 1 ]] || [[ "$1" = --caffe && $# -gt 1 ]] || [[ "$1" = --caffe2 && $# -gt 1 ]]; then 
    mustexit=1; 
else 
    mustexit=0; 
fi

while test $# -gt 0
do
	case "$1" in
		-g|--graph)
			echo "Generating graphs at the end of the tests ..."
			GENGRAPHS=1
			mustexit=0
			;;
		-d|--dockpull)
			echo "Pulling just the docker file"
			docker_login
			if [[ "$2" == "" || "$2" == -* ]]; then
				docker pull ${REPOSITORY}
			else
				docker pull $2
				REPOSITORY=$2
				shift 1
			fi
			;;
		--path)
			echo "--- Requested results directory at $2 ---"
			SET_PATH=$2 && mkdir -p ${SET_PATH}
			shift 1
			mustexit=0
			;;
		-n|--count)
			echo "--- Requested $2 of ${NUM_DEVICES} GPU devices ---"
			NUM_DEVICES=$2
			shift 1
			mustexit=0
			;;
		-2|--python2) # tell the script to use python version 2
			echo "Using python version 2"
			VERSION=2
			mustexit=0
			;;
		-r) # run with other parameters
			mustexit=0
			;;
		-re|--reset)
			reset_config
			;;
		-rr|--resetrun)
			reset_config
			mustexit=0
			;;
		-dc|-cd|--dockclean)
			rm Dockerfile 2> /dev/null
			rm gpu_stats.log 2> /dev/null
			docker_clean 2> /dev/null
			;;
		-cr|-rc|--cleanrun)
			rm Dockerfile 2> /dev/null
			rm gpu_stats.log 2> /dev/null
			docker_clean 2> /dev/null
			mustexit=0
			;;
		--docknuke) # use this with caution
			read -p "You're about to nuke all images from the file system. Are you sure? (y/n)" -n 1 -r
			echo    # (optional) move to a new line
			if [[ $REPLY =~ ^[Yy]$ ]]
			then
				docker_clean 2> /dev/null
				docker rmi $(docker images -a -q)
			fi
			;;
		--vmfix) #vm fault problem support
			sudo sysctl -w vm.max_map_count=1000000
			mustexit=0
			;;
		-a|--atitool)
			echo "Building atitool ..."
			../get_tools/get_atitool.py
			;;
		--caffe|--caffe2|--mi|--pytorch)
			;;
		-*|--*=)
			echo "Error: Unsupported flag $1" >&2
			;;
		*) echo "Error: Unknown Argument $1" >&2
			;;
	esac
	shift
done

if [ $mustexit == 1 ]; then exit 1; fi

echo -e "\n\n** MODE SELECTED (${RUNMODE}) **\n"

#check if docker assists
if [[ "$(dpkg -l | grep docker-ce 2> /dev/null)" == "" ]]; then
	echo "Installing Docker ... "
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
	sudo apt-get update
	sudo apt-get install -y docker-ce
fi

# call function to login
docker_login

# pull image if it doesn't exist locally
if [[ "$(docker images -q ${REPOSITORY} 2> /dev/null)" == "" ]]; then
	echo "Pulling image ${REPOSITORY} ... "
	docker pull ${REPOSITORY}
fi

# make sure PM logs works
echo "Checking for logging tools ... "
if [ ! -f "../get_tools/atitool/atitool" ]; then
	echo "Downloading atitool"
	( cd ../get_tools ; ./build.sh ) > /dev/null 2>&1
fi

if [ ${RUNMODE} == 'cf1' ]; then
	TESTCASES=(0);
elif [ ${RUNMODE} == 'cf2' ]; then
    MODELS=$($docker/pys/readcfg.py "${CONFIG_FULL}" 'model' 'c2')
    BATCH_SIZES=$($docker/pys/readcfg.py "${CONFIG_FULL}" 'batchsize' 'c2')
    ITERATIONS=$($docker/pys/readcfg.py "${CONFIG_FULL}" 'iterations' 'c2')
    LOOPS=$($docker/pys/readcfg.py "${CONFIG_FULL}" 'loops' 'c2')
    echo "==================="
    echo ${MODELS}
    echo ${BATCH_SIZES}
    echo ${ITERATIONS}
    echo ${LOOPS}

    #echo "models:${MODELS}, bsize: ${BATCH_SIZES}, esize:${EPOCH_SIZES}, nepochs:${NUM_EPOCHS}, loopss:${LOOPSS}"
    MODELS=(${MODELS//,/ })
    BATCH_SIZES=(${BATCH_SIZES//,/ })
    ITERATIONS=(${ITERATIONS//,/ })
    LOOPS=(${LOOPS//,/ })
    echo "==================="
    echo ${MODELS}
    echo ${BATCH_SIZES}
    echo ${ITERATIONS}
    echo ${LOOPS}

    TESTCASES="${!MODELS[@]}"

elif [ ${RUNMODE} == 'py' ]; then
    NETWORK=$($docker/pys/readcfg.py "${CONFIG_FULL}" 'network' 'py')
    BATCH_SIZE=$($docker/pys/readcfg.py "${CONFIG_FULL}" 'batchsize' 'py')
    ITERATIONS=$($docker/pys/readcfg.py "${CONFIG_FULL}" 'iterations' 'py')
    FP16=$($docker/pys/readcfg.py "${CONFIG_FULL}" 'fp16' 'py')
    LOOPS=$($docker/pys/readcfg.py "${CONFIG_FULL}" 'loops' 'py')
	
    echo "======================"
    echo $NETWORK
    echo $BATCH_SIZE	
    echo $ITERATIONS
    echo $FP16
    echo $LOOPS
	
    #echo "network:${NETWORK}, batchsize: ${BATCH_SIZES}, iterations:${ITERATIONS}"
    NETWORK=(${NETWORK//,/ })
    BATCH_SIZE=(${BATCH_SIZE//,/ })
    ITERATIONS=(${ITERATIONS//,/ })
    FP16=(${FP16//,/ })
    LOOPS=(${LOOPS//,/ })
    echo "======================"
    echo $NETWORK
    echo $BATCH_SIZE	
    echo $ITERATIONS
    echo $FP16	
    echo $LOOPS
	
    TESTCASES="${!NETWORK[@]}"
elif [ ${RUNMODE} == 'mi' ]; then
	LOOPSS=1
	TESTCASES=1
else
	MODELS=$($docker/pys/readcfg.py "${CONFIG_FULL}" 'model' 'tf' )
	DATAS=$($docker/pys/readcfg.py "${CONFIG_FULL}" 'dataset' 'tf')
	BATCH_SIZES=$($docker/pys/readcfg.py "${CONFIG_FULL}" 'batchsize' 'tf')
	NUMS_BATCHES=$($docker/pys/readcfg.py "${CONFIG_FULL}" 'batches' 'tf')
	LOOPSS=$($docker/pys/readcfg.py "${CONFIG_FULL}" 'loops' 'tf')

	MODELS=(${MODELS//,/ })
	DATAS=(${DATAS//,/ })
	BATCH_SIZES=(${BATCH_SIZES//,/ })
	NUMS_BATCHES=(${NUMS_BATCHES//,/ })
	LOOPSS=(${LOOPSS//,/ })

	TESTCASES="${!MODELS[@]}"
fi

if [ "${SET_PATH}" == "" ]; then
	# check if system is XGMI and label the folder
	is_xgmi=""
	[ ! -z "$(find /sys/devices -name xgmi_hive_id)" ] && is_xgmi="_xgmi"
	SET_PATH="${HOME}/results/docker${is_xgmi}_"${RUNMODE}"_$(date '+%d%m%Y-%H%M%S')" && mkdir -p ${SET_PATH}
fi

cp ${CONFIG_FULL} ${SET_PATH}/config.csv
if [ $($docker/pys/readcfg.py "${CONFIG_FULL}" 'repo') != ${REPOSITORY} ]; then	
    echo "Actual repo used during test: ${REPOSITORY}" >> ${SET_PATH}/config.csv; 
fi

python -u ../fetch_info/get_gpu_models.py | tee gpu_stats.log


# Run all test cases from this point
for idx in ${TESTCASES}
do
	# set timestamp for each test case in question
	TIMESTAMP=$(date '+%d%m%Y_%H%M%S')

	#Generate Dockerfile based on repo and other mode-specific parameters
	if [ ${RUNMODE} == 'cf1' ]; then

		RESULTS_DIR=${TIMESTAMP}
		echo "Running caffee with ${NUM_DEVICES} GPUs"
		./gens/caffe_gen.sh ${REPOSITORY} ${TESTLOOP} ${NUM_DEVICES}
	elif [ ${RUNMODE} == 'cf2' ]; then # for caffe2 mode of operation

		MODEL=${MODELS[$idx]}
        BATCH_SIZE=${BATCH_SIZES[$idx]}
        ITERATION=${ITERATIONS[$idx]}
		LOOPS=${LOOPS[$idx]}

        echo "==================="
 	echo ${MODEL}
	echo ${BATCH_SIZE}
	echo ${ITERATION}
	echo ${LOOPS}

	RESULTS_DIR=${MODEL}_${BATCH_SIZE}_${ITERATION}_${TIMESTAMP}
	echo "Running caffee2 with ${NUM_DEVICES} GPUs"
	echo "./gens/c2ffe_gen.sh repo:${REPOSITORY} model:${MODEL} GPUs:${NUM_DEVICES} batch-size:${BATCH_SIZE} iterations:${ITERATION} loops:${LOOPS} versoin:${VERSION}"
		./gens/c2ffe_gen.sh ${REPOSITORY} ${MODEL} ${NUM_DEVICES} ${BATCH_SIZE} ${ITERATION} ${LOOPS} ${VERSION}
	elif [ ${RUNMODE} == 'py' ]; then # for pytorch mode of operation
		NETWORK=${NETWORK[$idx]}
		BATCH_SIZE=${BATCH_SIZE[$idx]}
		ITERATIONS=${ITERATIONS[$idx]}
                FP=${FP[$idx]}
		LOOPS=${LOOPS[$idx]}
	        echo "======================"
	        echo $NETWORK
	        echo $BATCH_SIZE	
	        echo $ITERATIONS
                echo $FP16
	        echo $LOOPS
                RESULTS_DIR=${NETWORK}_${BATCH_SIZE}_${ITERATION}_${FP16}_${TIMESTAMP}
		echo "Running Pytorch with ${NUM_DEVICES} GPUs"
		echo "./gens/pytorch_gen.sh repo:${REPOSITORY} network:${NETWORK} GPUs:${NUM_DEVICES} batch-size:${BATCH_SIZE} fp16:${FP16} iterations:${ITERATIONS} loops:${LOOPS} "
		./gens/pytorch_gen.sh ${REPOSITORY} ${NETWORK} ${BATCH_SIZE} ${ITERATIONS} ${FP16} ${LOOPS} 
	elif [ ${RUNMODE} == 'mi' ]; then

		i=320
		t=1
		V=0
		F=0
		s=0
		W=12
		H=12
		c=74740
		n=100
		k=32
		y=3
		x=3
		p=0
		q=0
		u=1
		v=1
		LOOPS=1

		RESULTS_DIR="miopen_${TIMESTAMP}"
		echo "Running miopen with ${NUM_DEVICES} GPUs"
		echo "./gens/miopen_gen.sh repo:${REPOSITORY} ${i} ${t} ${V} ${F} ${s} ${H} ${W} ${n} ${c} ${k} ${y} ${x} ${p} ${q} ${u} ${v} ${NUM_DEVICES} ${LOOPS}"

		./gens/miopen_gen.sh ${REPOSITORY} ${i} ${t} ${V} ${F} ${s} ${H} ${W} ${n} ${c} ${k} ${y} ${x} ${p} ${q} ${u} ${v} ${NUM_DEVICES} ${LOOPS}
	else # for tensorflow mode of operation:Q


		MODEL=${MODELS[$idx]}
		DATASET=${DATAS[$idx]}
		BATCH_SIZE=${BATCH_SIZES[$idx]}
		NUM_BATCHES=${NUMS_BATCHES[$idx]}
		LOOPS=${LOOPSS[$idx]}

		if [ ${DATASET} == 'imagenet' ]; then
			REAL_TRAINING_DATA_SHARE="-v ${IMAGENET_DATA}:/realdata "
		elif [ ${DATASET} == 'cifar10' ]; then
			REAL_TRAINING_DATA_SHARE="-v ${CIPHER_DATA}:/realdata "
		fi

		RESULTS_DIR=${MODEL}_${DATASET}_${BATCH_SIZE}_${TIMESTAMP}
		echo "Running ${MODEL} with ${NUM_DEVICES} GPUs in batches of ${BATCH_SIZE} ..."
		./gens/tensor_gen.sh ${REPOSITORY} ${MODEL} ${NUM_DEVICES} ${BATCH_SIZE} ${NUM_BATCHES} ${LOOPS} ${VERSION} ${DATASET}
	fi

	FULLPATH=${SET_PATH}/${RESULTS_DIR} && mkdir -p ${FULLPATH}

	#File operations
	../fetch_info/fetch_info_runtime_fw.sh > ${FULLPATH}/host_runtime_fw_info.log
	cp ../fetch_info/fetch_info_runtime_fw.sh ${FULLPATH}/ && sed -i 24q ${FULLPATH}/fetch_info_runtime_fw.sh

	#Run Docker Model
	docker build -t docker_build .

	#Build tools
	echo "Launching pmlogs ... "
	(( ${ATIREZ} > 0 )) && ATITOOL_PIDS=$( cd ../get_tools; python -c "import os, atitool_lib; atitool_lib.run_atitool('${FULLPATH}/pm_${TIMESTAMP}.csv','${ATIREZ}')")

	echo -e "\n\n-------------------------------------- PARAMETERS -------------------------------------\n"
	echo "Real training" ${REAL_TRAINING_DATA_SHARE}
	echo "Fullpath" ${FULLPATH}
	docker run -it --privileged --network=host --device=/dev/kfd --device=/dev/dri --group-add video --cap-add=SYS_PTRACE --security-opt seccomp=unconfined ${REAL_TRAINING_DATA_SHARE}-v ${FULLPATH}:/results docker_build


	#Clean up files and tools
	echo "Cleaning up ..."
	(( ${ATIREZ} > 0 )) && kill ${ATITOOL_PIDS} 2> /dev/null
	#mv ${FULLPATH}/pm.csv ${FULLPATH}/pm_${RUNMODE}_${TIMESTAMP}.csv

	#Destroying tools, moving results and cleaning up docker images
	echo "Cleaning up docker files ... "
	#rm Dockerfile
	rm ${FULLPATH}/fetch_info_runtime_fw.sh

	docker_clean
	docker rmi docker_build -f
	echo -e "\n---------------------------------------------------------------------------------------\n\n"
done

mv gpu_stats.log ${SET_PATH}/gpu_stats.log

if [[ $GENGRAPHS == 1 ]]; then
	 ( cd ../fetch_info; python -c "import os, gen_pm_graphs as pm; os.chdir('${SET_PATH}'); pm.Run()" )
fi

echo "Logging out of docker ... "
docker logout

cd -

echo -e "\nPress ENTER to reset and clear terminal\n\n"
read -s -n 1 key
if [[ "$key" == "" ]]
then
	reset
	clear
fi
