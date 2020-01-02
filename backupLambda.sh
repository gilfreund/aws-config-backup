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

$AWSCMD lambda list-functions --query Functions[*].[FunctionArn,FunctionName] | while IFS=$'\t' read -r OBJECT_NAME functionName ; do 
	TARGET_FILE=$(buildTargetFilePrefix $functionName $functionName)
	$AWSGET lambda get-function --function-name $OBJECT_NAME > ${TARGET_FILE}.json
	backupIfNotNull $FEATURE list-tags tags
	if [[ "$(backupIfNotNull $FEATURE list-versions-by-function)" == "true" ]] ; then
		versions=$($AWSCMD lambda list-versions-by-function --function-name $OBJECT_NAME --query Versions[*].Version)
		for Version in $versions ; do 
			$AWSGET lambda get-function-configuration --function-name $OBJECT_NAME:$Version > $TARGET_FILE-"$Version".json 
			CODE_URL="$($AWSCMD lambda get-function --function-name $OBJECT_NAME:$Version --query Code.Location)"
			curl --silent "$CODE_URL" --output ${TARGET_FILE}-${Version}.zip
		done
	fi
	backupIfNotNull $FEATURE list-aliases aliases
	if [[ "$(backupIfNotNull $FEATURE list-aliases)" == "true" ]] ; then
		aliases=$($AWSCMD lambda list-aliases --function-name $OBJECT_NAME --query Aliases[*].Name)
		for alias in $aliases ; do
			$AWSGET lambda get-alias --function-name $OBJECT_NAME --name $alias > $TARGET_FILE-aliases-$alias.json
		done
	fi
done


commit Lambda
