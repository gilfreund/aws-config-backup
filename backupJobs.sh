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

function nicedate {
	echo $(date '+%d/%m/%Y %H:%M' --date=@$(( $(($1 + 500)) / 1000 )))
}
echo "Backing up Batch Jobs"

SUBDIR=$(mksubdir jobs)
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M')

echo "jobName,jobId,jobDefinition,status,jobQueue,image,vcpus,memory,exitCode,statusReason,created,waitTime,started,stopped,runTime" > ${SUBDIR}/$TIMESTAMP.log
for status in SUBMITTED PENDING RUNNABLE STARTING SUCCEEDED FAILED
do 
	$AWSCMD batch list-jobs --job-queue General --job-status $status --query jobSummaryList[*].[jobName,jobId] | while IFS=$'\t' read -r jobName jobId ; do
	TARGET_FILE=$(buildTargetFilePrefix $jobId $jobName)
		$AWSGET batch describe-jobs --jobs $jobId > ${TARGET_FILE}.json 
		$AWSCMD batch describe-jobs --jobs $jobId --query jobs[*].[jobName,jobId,jobDefinition,status,jobQueue,container.image,container.vcpus,container.memory,container.exitCode,createdAt,startedAt,stoppedAt,statusReason] | while IFS=$'\t' read -r jobName jobId jobDefinition status jobQueue image vcpus memory exitCode createdAt startedAt stoppedAt statusReason ; do
			jobQueue=${jobQueue#*/}
			jobDefinition=${jobDefinition#*/}
			image=${image##*/}
			created=$(nicedate $createdAt)
			if [[ $startedAt -gt 0 ]] ; then
				started=$(nicedate $startedAt)
				waitTime=$(date -u --date=@$(( (startedAt - createdAt) / 1000 )) +"%T")
				if [[ $stoppedAt -gt 0 ]] ; then
					stopped=$(nicedate $stoppedAt)
					runTime=$(date --universal --date=@$(( (stoppedAt - startedAt) / 1000 )) +"%T")
				fi
			fi
			echo "\"$jobName\",$jobId,\"$jobDefinition\",$status,\"$jobQueue\",\"$image\",$vcpus,$memory,$exitCode,\"$statusReason\",$created,$waitTime,$started,$stopped,$runTime" | tee ${TARGET_FILE}_$status.txt >> ${SUBDIR}/$TIMESTAMP.log
			$AWSCMD batch describe-jobs --jobs $jobId --query jobs[*].container.[logStreamName,taskArn,containerInstanceArn] | while IFS=$'\t' read -r logStreamName taskArn containerInstanceArn ; do
				$AWSCMD logs get-log-events --log-group-name '/aws/batch/job' --log-stream-name $logStreamName --start-from-head --limit 10000 --query events[*].message > ${TARGET_FILE}.log
			done
		done
	done
done

commit Batch Configurations
