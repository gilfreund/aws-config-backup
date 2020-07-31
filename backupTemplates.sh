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

echo "Backing up EC2 configurations"

SUBDIR=$(mksubdir templates)

$AWSCMD ec2 describe-launch-templates --query LaunchTemplates[*].[LatestVersionNumber,LaunchTemplateName]  | while read -r LatestVersionNumber LaunchTemplateName ; do
	if [[ $LaunchTemplateName != *Batch-lt* ]] && [[ $LaunchTemplateName != *launch-template-* ]] ; then
		if [[ ! -d ${SUBDIR}/${LaunchTemplateName} ]] ; then
			mkdir -p ${SUBDIR}/${LaunchTemplateName}
		fi
		$AWSGET ec2 describe-launch-templates --launch-template-names $LaunchTemplateName > ${SUBDIR}/${LaunchTemplateName}/${LaunchTemplateName}.json
		StartVersionNumber=1
		for (( VersionNumber=$StartVersionNumber; VersionNumber<=$LatestVersionNumber; VersionNumber++ )) ; do
			if [[ ! -f ${SUBDIR}/templates/${LaunchTemplateName}-${VersionNumber}.json ]] ; then
				$AWSGET ec2 describe-launch-template-versions --launch-template-name $LaunchTemplateName --versions $VersionNumber > ${SUBDIR}/${LaunchTemplateName}/${LaunchTemplateName}-${VersionNumber}.json
				UserData=$($AWSCMD ec2 describe-launch-template-versions --launch-template-name $LaunchTemplateName --versions $VersionNumber --query LaunchTemplateVersions[*].[LaunchTemplateData.UserData])
				echo $UserData | base64 -d > ${SUBDIR}/${LaunchTemplateName}/${LaunchTemplateName}-${VersionNumber}.mime
			fi
		done
	fi
done 

commit EC2 Configurations
