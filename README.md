Some AWS configuration have built-in version (IAM Policies and Launch Templates) and some don't (IAM Roles). Those that do have versioning have different number of version that can be saves (5 for IAM Policies). 

The scripts in this repository are used to backup AWS configuration items. The backups can be directer to a directory on a file system, a git manages directoty or an S3 bucket. The scripts can be run from an EC2 instance, a standalone Linux host, or from a container. 

# Configuration
General configuration is in the [backup.rc](backup.rc). Normally there is no need to chenge it. Site specific configution can be set in the [backup.user.rc] file. Those will include the prefered backup storage (GIT, FS or S3), the working direcroty (where the files will be stored for GIT or FS or the bucket name  for S3 backups)

## Parameters
| Variable | Value | Meaning |
|----------|-----------------------|----------------------------------------------|
| TARGET | FS | Backup to an arbirary directory |
|  | GIT | Backup to a git manages directory and commit |
|  | S3 | Backup to an S3 Bucket |
| WORKDIR | file system or s3 uri | Location to which the files will be stored |

# Requirments
## Permission
* List and read: Launch Templates, IAM Roles and Policies
* List, Read and Write: S3 Bucket (if used as a backend)
## OS Packages
* awscli (or aws-cli or install via pip)
* gawk
* coreutils (mkdir, date, mktemp, and cut)
* git (if using git as a backend)
