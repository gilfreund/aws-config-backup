#!/bin/bash
RCFILE="$(dirname $(readlink -f $0))/backup.rc"
if [[ -z $AWSCMD ]] ; then
	if [[ -f "$RCFILE" ]] ; then
		source "$RCFILE"
	else
		echo "Configuration file $RCFILE not found, exiting..."
		exit 1
fi

echo "Backing up Events configurations"

SUBDIR=$(mksubdir rules)
$AWSCMD events list-rules | awk '{print $2}' | awk -F"/" '{print $2}' | while read -r name ; do
$AWSGET events describe-rule --name $name > ${SUBDIR}/${name}.json
$AWSGET events list-targets-by-rule --rule $name > ${SUBDIR}/${name}.targets.json
done

commit Events Configurations
