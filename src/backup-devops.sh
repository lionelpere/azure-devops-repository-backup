#!/bin/bash
VERBOSE_MODE=false;
DRY_RUN=false;

#Get all parameters
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -p|--pat)
      PAT="$2"
      shift # past argument
      shift # past value
      ;;
    -d|--directory)
      BACKUP_ROOT_PATH="$2"
      shift # past argument
      shift # past value
      ;;
    -o|--organization)
      ORGANIZATION="$2"
      shift # past argument
      shift # past value
      ;;
    -r|--retention)
      RETENTION_DAYS="$2"
      shift # past argument
      shift # past value
      ;;
    -v|--verbose)
      VERBOSE_MODE=true
      shift # past argument
      ;;
    -x|--dryrun)
      DRY_RUN=true
      shift # past argument
      ;;
    *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

echo "=== Script parameters"
#echo "PAT               = ${PAT}"
echo "ORGANIZATION_URL  = ${ORGANIZATION}"
echo "BACKUP_ROOT_PATH  = ${BACKUP_ROOT_PATH}"
echo "RETENTION_DAYS    = ${RETENTION_DAYS}"
echo "DRY_RUN           = ${DRY_RUN}"
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
mkdir -p "${BACKUP_DIRECTORY}" && cd $_
echo "=== Backup folder created [${BACKUP_DIRECTORY}]"

#Initialize counters
PROJECT_COUNTER=0
REPO_COUNTER=0

 for project in $(echo "${ProjectList}" | jq -r '.[] | @base64'); do
    _jq() {
      echo ${project} | base64 -d | jq -r ${1}
    }
    echo "==> Backup project [${PROJECT_COUNTER}] [$(_jq '.name')] [$(_jq '.id')]"

    #Get current project name and normalize it to create folder
    CURRENT_PROJECT_NAME=$(_jq '.name')
    CURRENT_PROJECT_NAME=$(echo $CURRENT_PROJECT_NAME | sed -e 's/[^A-Za-z0-9._-]/_/g')
    mkdir -p "${BACKUP_DIRECTORY}/${CURRENT_PROJECT_NAME}" && cd $_ && pwd

    #Get Repository list for current project id.
    REPO_LIST_CMD="az repos list --organization ${ORGANIZATION} --project $(_jq '.id')"
    REPO_LIST=$($REPO_LIST_CMD)
    # echo ${REPO_LIST}

    for repo in $(echo "${REPO_LIST}" | jq -r '.[] | @base64'); do
        _jqR() {
          echo ${repo} | base64 -d | jq -r ${1}
        }
         echo "====> Backup repo [${REPO_COUNTER}][$(_jqR '.name')] [$(_jqR '.id')] [$(_jqR '.webUrl')]"

        #Get current repo name and normalize it to create folder
        CURRENT_REPO_NAME=$(_jqR '.name')
        CURRENT_REPO_NAME=$(echo $CURRENT_REPO_NAME | sed -e 's/[^A-Za-z0-9._-]/_/g')
        CURRENT_REPO_DIRECTORY="${BACKUP_DIRECTORY}/${CURRENT_PROJECT_NAME}/${CURRENT_REPO_NAME}"

        # mkdir -p ${CURRENT_REPO_DIRECTORY} && cd $_ && pwd

        # touch "dummyfile"

    if [[ "${DRY_RUN}" = true ]]; then
        echo "Simulate git clone ${CURRENT_REPO_NAME}"
        echo ${repo} | base64 -d >> "${CURRENT_REPO_NAME}-definition.json"
    else
        #Use Base64 PAT in headerto authentify on Git Repository
        git -c http.extraHeader="Authorization: Basic ${B64_PAT}" clone $(_jqR '.webUrl') ${CURRENT_REPO_DIRECTORY}
    fi
         ((REPO_COUNTER++))
    done

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
tar czf ${BACKUP_FOLDER}.tar.gz ${BACKUP_FOLDER}
backup_size_compressed=$(du -hs ${BACKUP_FOLDER}.tar.gz)
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
    echo "=== Apply retention policy (${RETENTION_DAYS} days)"
    find ${BACKUP_ROOT_PATH}/* -type f -mtime +${RETENTION_DAYS} -exec rm -rfv {} \; 
fi
