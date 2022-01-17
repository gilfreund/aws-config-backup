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

echo "Backing up IAM Users"

$AWSCMD iam generate-credential-report > /dev/null

SUBDIR=$(mksubdir users)
FEATURE=iam

$AWSCMD iam list-users --query Users[*].[UserName,Path] | while read -r OBJECT_NAME Path ; do
	if [[ ${#Path} -gt 1 ]] ; then
		buildTargetFilePrefix $OBJECT_NAME $Path
	else
		buildTargetFilePrefix $OBJECT_NAME root
	fi
	
	$AWSGET iam get-user --user-name $OBJECT_NAME > ${TARGET_FILE}.json
	backupIfNotNull $FEATURE list-attached-user-policies attached-policies
	backupIfNotNull $FEATURE list-groups-for-user groups
	backupIfNotNull $FEATURE list-user-tags tags
	backupIfNotNull $FEATURE list-mfa-devices mfa
	
	$AWSCMD iam list-user-policies --user-name $OBJECT_NAME --query PolicyNames[*] | while read -r PolicyNames ; do
		if [[ -n "${PolicyNames}" ]] ; then
			$AWSGET iam get-user-policy --user-name $OBJECT_NAME --policy-name $PolicyNames > ${TARGET_FILE}-policies.json
		fi
	done
	
	ACCESS_KEY_LIST=$(backupIfNotNull $FEATURE list-access-keys)
	if [[ "$ACCESS_KEY_LIST" == true ]] ; then
		backupIfNotNull $FEATURE list-access-keys keys
		$AWSCMD iam list-access-keys --user-name $OBJECT_NAME  --query AccessKeyMetadata[*].AccessKeyId | while read -r AccessKeyId ; do
			$AWSGET iam get-access-key-last-used --access-key-id $AccessKeyId > ${TARGET_FILE}-keys-$AccessKeyId.json
		done
	fi
	
	SSH_PUBLIC_KEYS=$(backupIfNotNull $FEATURE list-ssh-public-keys)
	if [[ "${SSH_PUBLIC_KEYS}" == "true" ]] ; then
		$AWSGET iam list-ssh-public-keys --user-name $OBJECT_NAME > ${TARGET_FILE}-ssh.json
		$AWSCMD iam list-ssh-public-keys --user-name $OBJECT_NAME --query SSHPublicKeys[*].[SSHPublicKeyId] | while read SSHPublicKeyId ; do
			$AWSGET iam get-ssh-public-key --user-name $OBJECT_NAME --ssh-public-key-id $SSHPublicKeyId --encoding PEM > ${TARGET_FILE}.pem
			$AWSGET iam get-ssh-public-key --user-name $OBJECT_NAME --ssh-public-key-id $SSHPublicKeyId --encoding SSH > ${TARGET_FILE}.ssh
		done
	fi


done
REPORT_DATE=$(date +%Y-%m-%d_%H-%M-%S)
$AWSGET iam get-credential-report > $SUBDIR/credential-report_${REPORT_DATE}.csv

commit IAM users 
