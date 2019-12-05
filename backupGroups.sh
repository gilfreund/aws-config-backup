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

function checkForValues {
	local result=$($AWSCMD iam $1 --user-name $UserName | awk {'print $2'})
	if [[ -n "${result}" ]] ; then
		if [[ -n "${2}" ]] ; then 
			$AWSGET iam $1 --user-name $UserName > ${TARGET_FILE}-$2.json
		else
			echo "true"
		fi
	fi
}

$AWSCMD iam list-groups | awk {'print $5" "$6'} | while read -r GroupName Path ; do
	$AWSGET iam get-group --group-name $GroupName > ${TARGET_FILE}.json
	$AWSGET iam list-group-policies --group-name $GroupName > ${TARGET_FILE}-policies.json
	$AWSCMD iam list-attached-group-policies --group-name $GroupName | awk {'print $4'} | while read -r PolicyNames ; do
		if [[ -n $PolicyNames ]] ; then
			$AWSGET iam get-group-policy --group-name $GroupName --policy-name $PolicyNames > ${TARGET_FILE}-attached-policies.json
		fi
	done
done

commit IAM Groups
