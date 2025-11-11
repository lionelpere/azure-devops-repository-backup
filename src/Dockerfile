 # syntax=docker/dockerfile:1
FROM ubuntu:22.04
RUN apt -y update
RUN apt -y install curl jq git bzip2
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
RUN az upgrade
RUN az extension add --name azure-devops
RUN mkdir -p /data
COPY . /home/devops
WORKDIR /home/devops
RUN chmod 777 ./*
VOLUME ["/data"]
ENTRYPOINT ["/bin/bash", "./docker-script.sh"]

