#!/bin/bash

# Run all backup scripts
for script in backup*.sh ; do 
	# excet myself...
	if [[ $script != ${0##*/} ]] ; then 
		echo "running $script"
		$(dirname "$(realpath $script)")/$script
	fi
done
