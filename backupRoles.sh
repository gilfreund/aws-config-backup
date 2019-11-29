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

SUBDIR=$(mksubdir roles)

$AWSCMD  iam  list-roles | grep ROLES | grep -v aws-service-role | awk '{print $2}' | awk -F":" '{print $NF}' | awk -F"/" '{print $2" "$NF}' | while read -r Path RoleName ; do
$AWSCMD iam list-role-policies --role-name ${RoleName} | awk '{print $2}' | while read -r PolicyNames ; do
	if [[ "$Path" != "${RoleName}" ]] ; then
		if [[ ! -d "${SUBDIR}/${Path}" ]] ; then
			mkdir "${SUBDIR}/${Path}"
		fi
		$AWSGET iam get-role --role-name ${RoleName} > ${SUBDIR}/${Path}/${RoleName}.json
		$AWSGET iam list-attached-role-policies --role-name ${RoleName} > ${SUBDIR}/${Path}/${RoleName}-attached-policies.json
		if [[ -n "${PolicyNames}" ]] ; then
			$AWSGET iam get-role-policy --role-name ${RoleName} --policy-name ${PolicyNames} > ${SUBDIR}/${RoleName}-role-policies.json
		fi
	fi
	$AWSGET iam get-role --role-name ${RoleName} > ${SUBDIR}/${RoleName}.json
	$AWSGET iam list-attached-role-policies --role-name ${RoleName} > ${SUBDIR}/${RoleName}-attached-policies.json
	if [[ -n ${PolicyNames} ]] ; then
		$AWSGET iam get-role-policy --role-name ${RoleName} --policy-name ${PolicyNames} > ${SUBDIR}/${RoleName}-role-policies.json
	fi
done
done

commit IAM Role Configurations
