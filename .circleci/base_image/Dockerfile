# Base Ubuntu image

FROM ubuntu:18.04

ENV UPDATED_AT 20180626T012240Z

ENV DEBIAN_FRONTEND noninteractive

RUN sed -i 's/# deb-src/deb-src/' /etc/apt/sources.list && \
    apt-get update && apt-get upgrade -y
RUN apt-get install -y git curl build-essential automake autoconf m4 libncurses5-dev \
    libwxgtk3.0-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev \
    squashfs-tools ssh-askpass libssl-dev bc m4 unzip cmake python locales
RUN update-locale LANG=C.UTF-8 && \
    git clone https://github.com:/asdf-vm/asdf.git ~/.asdf --branch v0.4.3 && \
    ~/.asdf/bin/asdf plugin-add erlang && \
    ~/.asdf/bin/asdf plugin-add elixir && \
    ~/.asdf/bin/asdf plugin-add nodejs
ADD .tool-versions /root
# ASDF configures kerl so that docs have to be buildable...
RUN apt-get install -y xsltproc fop libxml2-utils
RUN cd ~; ~/.asdf/bin/asdf install
RUN apt-get install -y xvfb
