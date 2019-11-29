#!/bin/bash
RCFILE="$(dirname $(readlink -f $0))/backup.rc"
if [[ -f "$RCFILE" ]] ; then
	source "$RCFILE"
else
	echo "Configuration file $RCFILE not found, exiting..."
	exit 1
fi

echo "Backing up all configurations"

# Run all backup scripts
for script in backup*.sh ; do 
	# excet myself...
	if [[ $script != ${0##*/} ]] ; then 
		$(dirname "$(realpath $script)")/$script
	fi
done
