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

echo "Backing up IAM Groups"

SUBDIR=$(mksubdir Groups)

$AWSCMD iam list-groups --query Groups[*].[GroupName,Path] | while read -r GroupName Path ; do
	if [[ ! -d ${SUBDIR}/${GroupName} ]] ; then
		mkdir -p ${SUBDIR}/${GroupName}
	fi
	$AWSGET iam get-group --group-name $GroupName > ${SUBDIR}/${GroupName}/${GroupName}.json
	# Get Group policies
	$AWSCMD iam list-group-policies --group-name $GroupName --query PolicyNames | while read -r PolicyNames ; do
		PolicyDirectory="${SUBDIR}/${GroupName}/policies"
		if [[ ! -d $PolicyDirectory ]] ; then 
			mkdir -p $PolicyDirectory
		fi
		$AWSGET iam  get-group-policy --group-name $GroupName --policy-name $PolicyNames > ${PolicyDirectory}/${PolicyNames}.json
	done
	$AWSGET iam list-attached-group-policies --group-name $GroupName > ${SUBDIR}/${GroupName}/${GroupName}-attached-policies.json
done
commit IAM Groups
