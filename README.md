# Azure DevOps Repository Backup

[![](https://deepwiki.com/badge.svg)](https://deepwiki.com/lionelpere/azure-devops-repository-backup)
![version](https://img.shields.io/badge/version-1.0.1-green)

> ⚠️ **Notice**: This repository is maintained with assistance from Claude AI. All code changes are carefully reviewed by human maintainers before being merged to ensure quality and security.

## :bulb: Introduction

Microsoft doesn't provide any built-in solution to backup Azure DevOps Services.

They recommend trusting the process as described in the [Data Protection Overview](https://docs.microsoft.com/en-us/azure/devops/organizations/security/data-protection?view=azure-devops) page.

However, most companies want to keep an **on-premise** backup of their code repositories for their Disaster Recovery Plan (DRP).

## Project Overview

This project provides a bash script to backup all Azure DevOps repositories of an Azure DevOps Organization.

A [PowerShell version](https://github.com/Pacman1988/BackupAzureDevopsRepos) of this script has been developed by [Pacman1988](https://github.com/Pacman1988).


## :fire: Bash Script

### Prerequisites

* **Bash shell** (If you're running on Windows, use [WSL2](https://docs.microsoft.com/en-us/windows/wsl/) to easily run a GNU/Linux environment)
* **Azure CLI**: [Installation guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
* **Azure CLI DevOps Extension**: [Installation guide](https://docs.microsoft.com/en-us/azure/devops/cli/?view=azure-devops)
* **Required packages**: `git`, `jq`, `base64` (available in most Linux distributions)

Interaction with the Azure DevOps API requires a [personal access token](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops).

For this backup script, you'll only need to generate a PAT with **read access on Code**.

### :computer: Usage

[Release notes](/docsrelease-notes.md)

```bash
./backup-devops.sh [-h] -p PAT -d backup-dir -o organization -r retention [-v] [-x] [-w]
```

**Parameters:**
- `-h` show this help text
- `-p` personal access token (PAT) for Azure DevOps **[REQUIRED]**
- `-d` backup directory path: the directory where to store the backup archive **[REQUIRED]**
- `-o` Azure DevOps organization URL (e.g. `https://dev.azure.com/organization`) **[REQUIRED]**
- `-r` retention days for backup files: how many days to keep the backup files **[REQUIRED]**
- `-v` verbose mode [default: false]
- `-x` dry run mode (no actual backup, only simulation) [default: false]
- `-w` backup project wiki [default: true]

## :whale: Docker Usage

![Docker Version](https://img.shields.io/badge/version-1.0.1-green)

If you don't want to install all those prerequisites or you want to isolate this process, you can run this task in a Docker image.

The Docker image and its documentation are available on Docker Hub: [lionelpere/azure-devops-repository-backup](https://hub.docker.com/r/lionelpere/azure-devops-repository-backup)

### :computer: Docker Command

```bash
docker run \
    -v YOUR_LOCAL_BACKUP_DIRECTORY:/data \
    -e DEVOPS_PAT=YOUR_PAT \
    -e DEVOPS_ORG_URL=YOUR_ORGANISATION_URL \
    -e RETENTION_IN_DAYS=7 \
    -e DRY_RUN=true \
    -e WIKI=true \
    lionelpere/azure-devops-repository-backup
```

**Environment Variables:**
- `DEVOPS_PAT`: Your Personal Access Token
- `DEVOPS_ORG_URL`: Your Azure DevOps organization URL
- `RETENTION_IN_DAYS`: Number of days to keep backup files (e.g., 7)
- `DRY_RUN`: Set to `true` to create dummy files instead of cloning repositories
- `WIKI`: Set to `true` to also backup the Wiki structure of projects 
