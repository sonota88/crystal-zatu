FROM ubuntu:24.04

RUN apt update \
  && apt install -y --no-install-recommends \
    ca-certificates \
    ruby \
    wget \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# --------------------------------
# Crystal

RUN apt update \
  && apt install -y --no-install-recommends \
    gcc \
    libc6-dev libpcre2-dev libevent-dev \
    pkgconf \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# --------------------------------
# shards

RUN apt update \
  && apt install -y --no-install-recommends \
    git \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# --------------------------------

# /usr/bin/ld: cannot find -lSDL2 (this usually means you need to install the development package for libSDL2): No such file or directory

RUN apt update \
  && apt install -y --no-install-recommends \
    libsdl2-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# --------------------------------

ARG USER
ARG GROUP

# https://askubuntu.com/questions/1513927/ubuntu-24-04-docker-images-now-includes-user-ubuntu-with-uid-gid-1000
RUN userdel -r ubuntu

RUN groupadd ${USER} \
  && useradd ${USER} -g ${GROUP} -m

USER ${USER}

# --------------------------------

WORKDIR /home/${USER}/

ARG version="1.14.0"
ARG archive_file="crystal-${version}-1-linux-x86_64.tar.gz"

RUN wget -q \
    "https://github.com/crystal-lang/crystal/releases/download/${version}/${archive_file}" \
  && tar -xf "$archive_file" \
  && mv "crystal-${version}-1/" "crystal/" \
  && rm "$archive_file"

ENV PATH="/home/${USER}/crystal/bin:${PATH}"

# --------------------------------

RUN mkdir /home/${USER}/work

WORKDIR /home/${USER}/work

ENV IN_CONTAINER=1
