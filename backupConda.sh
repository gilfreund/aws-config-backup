#!/bin/bash
RCFILE="$(dirname $(readlink -f $0))/backup.rc"
if [[ -z $AWSCMD ]] ; then
	if [[ -f "$RCFILE" ]] ; then
		source "$RCFILE"
	else
		echo "Configuration file $RCFILE not found, exiting..."
		exit 1
fi

echo "Backing up conda configurations"

if [[ -z CONDA_ROOT ]] ; then
	echo "CONDA_ROOT is not defined in backup.user.rc"
	echo "Cannot backup conda"
	exit 1
fi

ACTIVATE="$CONDA_ROOT/bin/activate"
if [ -z $CONDA_EXE ]
then
	if [ -f $ACTIVATE ]
	then
		source $ACTIVATE
	else
		echo "can't find $ACTIVATE" 
		exit 1
	fi
fi

SUBDIR=$(mksubdir .)
for env in $(conda env list | tail  --lines=+3 | awk '{print $1}')
do 
	echo Processing $env
	echo -e "\tExport environenment"
	conda env export --name $env > ${SUBDIR}/${env}.yaml
	echo -e "\tExport specs"
	conda list --explicit --name ${env} > ${SUBDIR}/${env}-dependencies.txt
	HISTORY="${CONDA_ROOT}/envs/${env}/conda-meta/history"
	if [[ -f $HISTORY ]] ; then
		echo -e "\tCopy history"
		cp $HISTORY ${SUBDIR}/${env}-history.txt
	fi
done

commit conda Configurations
