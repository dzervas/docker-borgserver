############################################################
# Dockerfile to build borgbackup server images
# Based on Debian
############################################################
FROM debian:testing-slim

ENV BORG_SERVE_ARGS=
ENV BORG_APPEND_ONLY=no
ENV BORG_ADMIN=
ENV PUID=1000
ENV PGID=1000
ENV SSH_HOST_DIR=/keys/host
ENV SSH_CLIENT_DIR=/keys/client

# Volume for SSH-Host-Keys
VOLUME /keys/host

# Volume for SSH-Client-Keys
VOLUME /keys/client

# Volume for borg repositories
VOLUME /backup

RUN export DEBIAN_FRONTEND=noninteractive && \
		apt-get update && \
		apt-get -y --no-install-recommends install \
		borgbackup openssh-server && \
		apt-get -y dist-upgrade && apt-get clean

RUN useradd -s /bin/bash -m -U borg && \
		mkdir -p /home/borg/.ssh /backup "${SSH_CLIENT_DIR}" "${SSH_HOST_DIR}" && \
		chmod 700 /home/borg/.ssh && \
		touch /home/borg/.ssh/authorized_keys && \
		chown -R borg:borg /home/borg /backup "${SSH_HOST_DIR}" && \
		chown -R root:borg "${SSH_CLIENT_DIR}" && \
		chmod -R 750 "${SSH_CLIENT_DIR}" && \
		mkdir /run/sshd && \
		rm -f /etc/ssh/ssh_host*key* && \
		rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

COPY ./data/sshd_config /etc/ssh/sshd_config
COPY ./data/init.sh /init.sh

USER borg
EXPOSE 2222/tcp

ENTRYPOINT [ "/init.sh" ]
CMD [ "/usr/sbin/sshd", "-D", "-e" ]
