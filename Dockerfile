#FROM perl:5.36.0
FROM --platform=linux/amd64 perl:5.36.0

MAINTAINER Tsuyoshi Torii <toritori0318@gmail.com>

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
 && unzip awscliv2.zip \
 && ./aws/install

RUN mkdir p5-Yogafire
WORKDIR p5-Yogafire
ADD . .
RUN cpanm . --notest

RUN touch /root/.yoga
RUN chmod 600 /root/.yoga

RUN curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
RUN dpkg -i session-manager-plugin.deb

RUN apt update -y && apt install tmux -y

ENTRYPOINT ["yoga"]
