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

echo "Backing up Lambda"

SUBDIR=$(mksubdir functions)
FEATURE=lambda

$AWSCMD lambda list-functions | grep FUNCTIONS | awk -F '\t' {'print $5" "$6'} | while read -r OBJECT_NAME functionName ; do 
	TARGET_FILE=$(buildTargetFilePrefix $functionName)
	$AWSGET lambda get-function --function-name $OBJECT_NAME > ${TARGET_FILE}.json
	backupIfNotNull list-tags tags
	if [[ "$(backupIfNotNull list-versions-by-function)" == "true" ]] ; then
		$AWSCMD lambda list-versions-by-function --function-name $OBJECT_NAME | grep VERSIONS | awk -F '\t' {'print $NF'}  | while read -r Version ; do
			$AWSCMD lambda get-function-configuration --function-name $OBJECT_NAME:$Version > $TARGET_FILE-$Version.json 
		done
	fi
	backupIfNotNull list-aliases aliases
	if [[ "$(backupIfNotNull list-aliases)" == "true" ]] ; then
		$AWSGET lambda list-aliases --function-name $OBJECT_NAME | grep ALIASES | awk -F '\t' {'print $4'} | while read -r aliases ; do
			$AWSGET get-alias --function-name $OBJECT_NAME --name $aliases > $TARGET_FILE-aliases-$aliases.json
		done
	fi
done


commit Lambda
