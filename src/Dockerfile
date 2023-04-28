 # syntax=docker/dockerfile:1
FROM opensuse/leap
RUN zypper install -y azure-cli
RUN az extension add --name azure-devops
RUN mkdir -p /data
COPY . /home/devops
WORKDIR /home/devops
RUN chmod 777 ./*
VOLUME ["/data"]
ENTRYPOINT ["/bin/bash", "./docker-script.sh"]

