FROM python:3.10.14-bookworm

COPY scripts/get_root_cert.sh /usr/local/scripts/get_root_cert.sh
RUN bash /usr/local/scripts/get_root_cert.sh

RUN apt-get update \
    && apt-get install ca-certificates \
    && update-ca-certificates \
    && apt-get install -y vim curl libgomp1 
    
USER vscode
ENV JULIA_REVISE_POLL=1