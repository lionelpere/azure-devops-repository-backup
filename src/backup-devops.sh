#!/usr/bin/env bash

# set -o pipefail extends -e by making any failure anywhere in a pipeline fatal
set -euo pipefail

# enable extended pathname expansion (e.g. $ ls !(*.jpg|*.gif))
shopt -s extglob

# min bash 4 version
[[ "${BASH_VERSINFO[0]}" -lt 4 ]] && die "Bash >=4 required"

################################################################################
### variables and defaults
################################################################################
VERBOSE_MODE=false;
DRY_RUN=false;
PROJECT_WIKI=false;

BACKUP_SUCCESS=true;

################################################################################
### FUNCTIONS
################################################################################

# check if command is available
function installed {
  command -v "${1}" >/dev/null 2>&1
}

# die and exit with code 1
function die {
  >&2 printf '%s %s\n' "Fatal: " "${@}"
  exit 1
}

# usage function
function usage {
  usage="$(basename "$0") [-h] [-p pat] [-d directory] [-o organization] [-r retention] [-v] [-x] -- backup Azure DevOps repositories
where:
    -h  show this help text
    -p  personal access token (PAT) for Azure DevOps
    -d  backup directory path
    -o  organization URL (e.g. https://dev.azure.com/organization)
    -r  retention days for backup files
    -v  verbose mode
    -x  dry run mode (no actual backup)
    -w  backup project wiki"
  printf '%s\n' "${usage}"  
}

################################################################################
### MAIN
################################################################################

# check for required commands
deps=(jq base64 git az)
for dep in "${deps[@]}"; do
  installed "${dep}" || die "Missing '${dep}'"
done

# parse options
while getopts ':p:d:o:r:vxwh' option; do
  case "$option" in
    p) PAT=$OPTARG
       ;;
    d) BACKUP_ROOT_PATH=$OPTARG
       ;;
    o) ORGANIZATION=$OPTARG
       ;;
    r) RETENTION_DAYS=$OPTARG
       ;;
    v) VERBOSE_MODE=true
       ;;
    x) DRY_RUN=true
       ;;
    w) PROJECT_WIKI=true
       ;;
    h) usage
       exit 0
       ;;
    :) printf 'missing argument for -%s\n' "$OPTARG" >&2
       usage
       exit 1
       ;;
   \?) printf 'illegal option: -%s\n' "$OPTARG" >&2
       usage
       exit 1
       ;;
  esac
done
shift $((OPTIND - 1))

# deal with required options
# die if PAT is empty
[[ -z "${PAT}" ]] && die "PAT is required (-p option)"
# die if directory argument is empty
[[ -z "${BACKUP_ROOT_PATH}" ]] && die "Backup directory is required (-d option)"
# die if organization argument is empty
[[ -z "${ORGANIZATION}" ]] && die "Organization URL is required (-o option)"
# die if retention argument is empty
[[ -z "${RETENTION_DAYS}" ]] && die "Retention days is required (-r option)"
# die if retention argument is not a number
[[ ! "${RETENTION_DAYS}" =~ ^[0-9]+$ ]] && die "Retention days must be a number"
# die if retention argument is less than 1
[[ "${RETENTION_DAYS}" -lt 1 ]] && die "Retention days must be greater than 0"
# die if retention argument is greater than 365
[[ "${RETENTION_DAYS}" -gt 365 ]] && die "Retention days must be less than 365"
# die if directory does not exist
[[ ! -d "${BACKUP_ROOT_PATH}" ]] && die "Backup directory does not exist"
# die if directory is not writable
[[ ! -w "${BACKUP_ROOT_PATH}" ]] && die "Backup directory is not writable"
# die if directory is not a directory
[[ ! -d "${BACKUP_ROOT_PATH}" ]] && die "Backup directory is not a directory"

echo "=== Azure DevOps Repository Backup Script ==="

set -- "${POSITIONAL[@]}" # restore positional parameters

echo "=== Script parameters"
#echo "PAT               = ${PAT}"
echo "ORGANIZATION_URL  = ${ORGANIZATION}"
echo "BACKUP_ROOT_PATH  = ${BACKUP_ROOT_PATH}"
echo "RETENTION_DAYS    = ${RETENTION_DAYS}"
echo "DRY_RUN           = ${DRY_RUN}"
echo "PROJECT_WIKI      = ${PROJECT_WIKI}"
echo "VERBOSE_MODE      = ${VERBOSE_MODE}"

#Store script start time
start_time=$(date +%s)

#Install the Devops extension
echo "=== Install DevOps Extension"
az extension add --name 'azure-devops'

#Set this environment variable with a PAT will 'auto login' when using 'az devops' commands
echo "=== Set AZURE_DEVOPS_EXT_PAT env variable"
export AZURE_DEVOPS_EXT_PAT=${PAT} 
#Store PAT in Base64
B64_PAT=$(printf "%s"":${PAT}" | base64)

echo "=== Get project list"
ProjectList=$(az devops project list --organization ${ORGANIZATION} --query 'value[]')

#Create backup folder with current time as name
BACKUP_FOLDER=$(date +"%Y%m%d%H%M")
BACKUP_DIRECTORY="${BACKUP_ROOT_PATH}/${BACKUP_FOLDER}"
mkdir -p "${BACKUP_DIRECTORY}"
echo "=== Backup folder created [${BACKUP_DIRECTORY}]"

#Initialize counters
PROJECT_COUNTER=0
REPO_COUNTER=0

 for project in $(echo "${ProjectList}" | jq -r '.[] | @base64'); do

    WIKI_COUNTER=0

    _jq() {
      echo ${project} | base64 -d | jq -r ${1}
    }
    echo "==> Backup project [${PROJECT_COUNTER}] [$(_jq '.name')] [$(_jq '.id')]"

    #Get current project name and normalize it to create folder
    CURRENT_PROJECT_NAME=$(_jq '.name')
    CURRENT_WIKI_PROJECT_NAME=$(echo $CURRENT_PROJECT_NAME | sed -e 's/[^A-Za-z0-9._\(\)-]/-/g')    
    CURRENT_PROJECT_NAME=$(echo $CURRENT_PROJECT_NAME | sed -e 's/[^A-Za-z0-9._\(\)-]/_/g')
    mkdir -p "${BACKUP_DIRECTORY}/${CURRENT_PROJECT_NAME}" && pwd

    #Get Repository list for current project id.
    REPO_LIST_CMD="az repos list --organization ${ORGANIZATION} --project $(_jq '.id')"
    REPO_LIST=$($REPO_LIST_CMD)
    # echo ${REPO_LIST}

    for repo in $(echo "${REPO_LIST}" | jq -r '.[] | @base64'); do
        _jqR() {
           echo ${repo} | base64 -d | jq -r ${1}           
        }
        
        # There must always be at least one repository per Team Project.
        if [[ ${WIKI_COUNTER} = 0 ]]; then
          CURRENT_BASE_WIKI_URL=$(_jqR '.webUrl')  
          ((WIKI_COUNTER++))        
        fi

        echo "====> Backup repo [${REPO_COUNTER}][$(_jqR '.name')] [$(_jqR '.id')] [$(_jqR '.webUrl')]"
                
        #Get current repo name and normalize it to create folder
        CURRENT_REPO_NAME=$(_jqR '.name')
        CURRENT_REPO_NAME=$(echo $CURRENT_REPO_NAME | sed -e 's/[^A-Za-z0-9._\(\)-]/_/g')
        CURRENT_REPO_DIRECTORY="${BACKUP_DIRECTORY}/${CURRENT_PROJECT_NAME}/repo/${CURRENT_REPO_NAME}"

        # mkdir -p ${CURRENT_REPO_DIRECTORY} && cd $_ && pwd

        # touch "dummyfile"

    if [[ "${DRY_RUN}" = true ]]; then
        echo "Simulate git clone ${CURRENT_REPO_NAME}"
        mkdir -p ${CURRENT_REPO_DIRECTORY}
        echo ${repo} | base64 -d >> "${CURRENT_REPO_DIRECTORY}/${CURRENT_REPO_NAME}-definition.json"
    else
        # check if repo is disabled and skip it
        # disabled repos cannot be accessed
        if [[ "$(_jqR '.isDisabled')" = false ]]; then
          # Use Base64 PAT in header to authenticate on Git Repository
          git -c http.extraHeader="Authorization: Basic ${B64_PAT}" clone $(_jqR '.webUrl') ${CURRENT_REPO_DIRECTORY}
          if [ $? -ne 0 ]; then
            echo "====> Backup failed for repo [${CURRENT_REPO_NAME}]"
            BACKUP_SUCCESS=false
          fi
        else
          echo "====> Skipping disabled repo: [${CURRENT_REPO_NAME}]"
        fi
    fi        

        ((REPO_COUNTER++))
    done

    if [[ "${PROJECT_WIKI}" = true ]]; then
        CURRENT_WIKI_DIRECTORY="${BACKUP_DIRECTORY}/${CURRENT_PROJECT_NAME}/wiki/${CURRENT_WIKI_PROJECT_NAME}"             
        CURRENT_BASE_WIKI_URL=$(echo $CURRENT_BASE_WIKI_URL | sed -E 's/(https:\/\/dev.azure.com\/.+\/_git\/)(.+)$/\1/g')
        CURRENT_WIKI_URL="${CURRENT_BASE_WIKI_URL}${CURRENT_WIKI_PROJECT_NAME}.wiki"

        echo "====> Backup Wiki repo ${CURRENT_WIKI_URL}"            
        git -c http.extraHeader="Authorization: Basic ${B64_PAT}" clone ${CURRENT_WIKI_URL} ${CURRENT_WIKI_DIRECTORY}
    fi

    ((PROJECT_COUNTER++))
done

#Backup summary
#echo "=== Backup structure ==="
#find ${BACKUP_DIRECTORY} -maxdepth 2
end_time=$(date +%s)
elapsed=$(( end_time - start_time ))
backup_size_uncompressed=$(du -hs ${BACKUP_DIRECTORY})

cd ${BACKUP_ROOT_PATH}
echo "=== Compress folder"
tar cjf ${BACKUP_FOLDER}.tar.bz ${BACKUP_FOLDER}
backup_size_compressed=$(du -hs ${BACKUP_FOLDER}.tar.bz)
echo "=== Remove raw data in folder"
rm -rf ${BACKUP_FOLDER}

echo "=== Backup completed ==="
echo  "Projects : ${PROJECT_COUNTER}"
echo  "Repositories : ${REPO_COUNTER}"

echo "Size : ${backup_size_uncompressed} (uncompressed) - ${backup_size_compressed} (compressed)"
eval "echo Elapsed time : $(date -ud "@$elapsed" +'$((%s/3600/24)) days %H hr %M min %S sec')"

if [[ -z "${RETENTION_DAYS}" ]]; then
    echo "=== No retention policy"
else
    if [[ "${BACKUP_SUCCESS}" = true ]]; then
        # doublecheck for BACKUP_ROOT_PATH
        if [ -n "$(BACKUP_ROOT_PATH)" -a "$(BACKUP_ROOT_PATH)" != "/" ]; then
          echo "=== Apply retention policy (${RETENTION_DAYS} days)"
          find ${BACKUP_ROOT_PATH} -mindepth 1 -maxdepth 1 -type f -mtime +${RETENTION_DAYS} -delete
        else
          echo "=== Skip deletion due to invalid backup directory (${BACKUP_ROOT_PATH})"
        fi
    else
        echo "=== Backup failed, retention policy not applied"
    fi
fi
