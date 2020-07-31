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

echo "Backing up IAM Roles configurations"

function checkForValues {
	local result=$($AWSCMD iam $1 --role-name $RoleName | awk -F '\t' {'print $2'})
	if [[ -n "${result}" ]] ; then
		if [[ -n "${2}" ]] ; then 
			$AWSGET iam $1 --role-name $RoleName > ${TARGET_FILE}-$2.json
		else
			echo "true"
		fi
	fi
}

SUBDIR=$(mksubdir roles)

$AWSCMD iam  list-roles --query Roles[*].[Path,RoleName] | while read -r Path RoleName ; do
	if [[ ${#Path} -gt 1 ]] ; then
		if [[ ! -d ${SUBDIR}${Path} ]] ; then
			mkdir ${SUBDIR}${Path}
		fi
		TARGET_FILE="${SUBDIR}${Path}${RoleName}"
	else
		TARGET_FILE="${SUBDIR}/${RoleName}"
	fi
	$AWSGET iam get-role --role-name ${RoleName} > ${TARGET_FILE}.json
	checkForValues list-attached-role-policies attached-policies
	checkForValues list-instance-profiles-for-role instance-profiles
	if [[ "$(checkForValues list-role-policies)" == "true" ]] ; then 
		$AWSCMD iam list-role-policies --role-name ${RoleName} --query PolicyNames[*] | while read -r PolicyNames ; do
			$AWSGET iam get-role-policy --role-name ${RoleName} --policy-name ${PolicyNames} > ${TARGET_FILE}-role-policies.json
		done
	fi
done

commit IAM Role Configurations
