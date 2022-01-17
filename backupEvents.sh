#!/bin/bash
RCFILE="$(dirname $(readlink -f $0))/backup.rc"

if [[ -z $AWSCMD || -z $TARGET_TYPE || -z $TARGET_LOCATION || -z $TEMPDIR  ]] ; then
	if [[ -f "$RCFILE" ]] ; then
		source "$RCFILE"
	else
		echo "Configuration file $RCFILE not found, exiting..."
		exit 1
	fi
fi

echo "Backing up Events configurations"

SUBDIR=$(mksubdir rules)
$AWSCMD events list-rules  --query Rules[*].[Name] | while read -r name ; do
	if [[ ! -d ${SUBDIR}/${name} ]] ; then
		mkdir -p ${SUBDIR}/${name}
	fi
	$AWSGET events describe-rule --name $name > ${SUBDIR}/${name}/${name}.json
	$AWSGET events list-targets-by-rule --rule $name > ${SUBDIR}/${name}/${name}.targets.json
done

commit Events Configurations
