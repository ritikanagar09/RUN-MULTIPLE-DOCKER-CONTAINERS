#!/usr/bin/env bash

WORK_DIR="/aestest"

is_num ()
{
	re='^[0-9]+$'
	[[ $1 =~ $re ]]
}

show_help ()
{
	echo ""
	echo "Usage:"
	echo "runner.sh [executable] [repetition] [containers]"
	echo ""
	echo "Examples:"
	echo "runner.sh main.exe 10 30"
	echo "runner.sh 10 30 -exe main.exe"
	echo "runner.sh main.exe -c 30 -r 10"
	echo ""
}

exe_name=""
n_containers=""
n_repetition=""

positional_args=()
processorCount=$(nproc --all)

# parse keyword arguments
while [[ $# -gt 0 ]]; do
	case $1 in
		-h|-help)
			show_help
			exit 0
			;;
		-c|-containers)
			n_containers="$2"
			shift
			shift
			;;
		-r|-repetition)
			n_repetition="$2"
			shift
			shift
			;;
		-e|-exe)
			exe_name="$2"
			shift
			shift
			;;
		-*)
			echo "error: unknown option: $1"
			show_help
			exit 1
			;;
		*)
			positional_args+=("$1")
			shift
			;;
	esac
done

set -- "${positional_args[@]}"

# parse positional arguments
if [[ -z $n_containers ]]; then
	positional_args=()
	while [[ $# -gt 0 ]]; do
		is_num "$1"
		status=$?
		if [[ -z $n_repetition ]] && (exit $status); then
			n_repetition="$1"
		elif [[ -z $n_containers ]] && (exit $status); then
			n_containers="$1"
		elif [[ -z $exe_name ]] && ! (exit $status); then
			exe_name="$1"
		else
			positional_args+=("$1")
		fi
		shift
	done
fi

# use default values if not provided
if [[ -z $n_containers ]]; then
	if [[ $processorCount -gt 1 ]]; then
		n_containers=$(($processorCount - 1))
	else
		n_containers=1
	fi
fi
if [[ -z $n_repetition ]]; then
	n_repetition=1
fi
if [[ -z $exe_name ]]; then
	exe_name="main.exe"
fi

echo ""
echo "**************** INFO ******************"
echo "Executable name: $exe_name"
echo "No. of container(s): $n_containers"
echo "No. of repetition(s): $n_repetition"
echo "****************************************"
echo ""

containers=()
runCounter=()
runStatus=()

# start containers
for (( i=0; i<n_containers; i++))
do
	containers[$i]="benchmark_$(($i + 1))"
	runCounter[$i]=$n_repetition
	runStatus[$i]=""
	docker run --name ${containers[$i]} --rm -d aestesting >/dev/null
    echo "-> create docker container ${containers[$i]} successfully"
done

# wait for containers to be up and running, perform cleanup
upCount=$n_containers
echo "wait for docker containers to be up and running..."
while [[ $upCount -gt 0 ]]
do
	for (( i=0; i<n_containers; i++))
	do
		# x=$(shuf -i 1-2 -n 1)
		if [[ "$(docker container inspect -f '{{.State.Running}}' "${containers[$i]}")" == "true" ]]
		# if [[ $x -gt 1 ]]
		then
			# docker exec "${containers[$i]}" rm -f "$WORK_DIR/log.txt"
			# echo "-> delete \"${containers[$i]}\":$WORK_DIR/log.txt"
            echo "-> container ${containers[$i]} is up and running"
			upCount=$(($upCount - 1))
		fi
	done
	sleep 0.01
done

# main loop
#loop for exec command of docker 
# shows the exit status of previous command 
# it just runs a new command in the docker container
totalRunCount=$(($n_containers * $n_repetition))
while [[ $totalRunCount -gt 0 ]]
do
	for (( i=0; i<n_containers; i++))
	do
		if [[ ${runCounter[$i]} -gt 0 ]]
		then
            docker top "${containers[$i]}" | grep "$exe_name" >/dev/null
            status=$?
            if !(exit $status)
			then
				echo "-> run $(($n_repetition - ${runCounter[$i]} + 1))/$n_repetition in ${containers[$i]}"
				docker exec -d "${containers[$i]}" /bin/sh -c "$WORK_DIR/$exe_name >> $WORK_DIR/log.txt" 
				runStatus[$i]=$(docker top "${containers[$i]}" | grep "$exe_name" | awk '{printf $2}')
                runCounter[$i]=$((${runCounter[$i]} - 1))
                totalRunCount=$(($totalRunCount - 1))
			fi
		fi
	done
	echo "-----"
	sleep 0.05
done

#wait for containers to closed /free
upCount=$n_containers
echo "wait for docker containers to become free for deletion."

for (( i=0; i<n_containers; i++))
do
    status=0
    while (exit $status) 
    do
        docker top "${containers[$i]}" | grep "$exe_name" >/dev/null
        status=$?
        sleep 0.01
    done
    echo "-> container ${containers[$i]} can be deleted now"
    upCount=$(($upCount - 1))
done

# copy logs and delete containers
backup_dir="logs/$(date +'%y.%m.%d-%H.%M.%S')"
mkdir -p "$backup_dir"
for (( i=0; i<n_containers; i++))
do
	echo "-> copy logs from ${containers[$i]}:$WORK_DIR/log.txt ./$backup_dir/${containers[$i]}-log.txt"
	docker cp "${containers[$i]}:$WORK_DIR/log.txt" "./$backup_dir/${containers[$i]}.txt"
	echo "-> delete docker container ${containers[$i]}"
	docker rm -f "${containers[$i]}" >/dev/null
done
