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

echo "Backing up Lambda Layers	"

SUBDIR=$(mksubdir layers)
FEATURE=lambda

$AWSCMD lambda list-layers --query Layers[*].[LayerArn,LayerName,LatestMatchingVersion.Version] | while IFS=$'\t' read -r OBJECT_NAME LayerName Version ; do 
	TARGET_FILE=$(buildTargetFilePrefix $LayerName $LayerName)
	$AWSGET lambda get-layer-version --layer-name $OBJECT_NAME --version-number $Version > ${TARGET_FILE}-$Version.json
	CODE_URL="$($AWSCMD lambda get-layer-version --layer-name $OBJECT_NAME --version-number $Version --query Content.Location)"
	curl --silent "$CODE_URL" --output ${TARGET_FILE}-${Version}.zip
	policy=$($AWSCMD lambda get-layer-version-policy  --layer-name $OBJECT_NAME --version-number $Version 2> /dev/null | awk {'print $2'} )
	if [[ -n "${result}" ]] ; then
		$AWSGET lambda get-layer-version-policy  --layer-name $OBJECT_NAME --version-number $Version > ${TARGET_FILE}-$Version-policy.json
	fi

done


commit Lambda
