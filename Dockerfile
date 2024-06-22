# syntax = docker/dockerfile:experimental
ARG ARG_DISTVER
FROM ubuntu:${ARG_DISTVER}

# for DISTRO Cache --->
ARG ARG_CACHEPROXY_IP
ARG ARG_CACHEPROXY_PORT

ENV CACHEPROXY ${ARG_CACHEPROXY_IP}:${ARG_CACHEPROXY_PORT}
WORKDIR /etc/apt/apt.conf.d/
# RUN echo "Acquire::http { Proxy http://${ARG_CACHEPROXY_IP}; };" >> 01proxy
# if cache maintenance completed
RUN sed -ie "s/http:\/\/archive.ubuntu.com\/ubuntu\//http:\/\/${CACHEPROXY}\/archive.ubuntu.com\/ubuntu/g" /etc/apt/sources.list
WORKDIR /
# ---> for DISTRO Cache

# USER, PASSWD, UID, GID
ARG ARG_USER
ARG ARG_PASS
ARG ARG_UID
ARG ARG_GID

ENV USERNAME ${ARG_USER}
ENV GROUPNAME "developer"
ENV USERPASSWD ${ARG_PASS}

# Upgrade OS
RUN apt-get update -q && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

# Step 1. Prepare the development environment on the host PC by installing the following packages
RUN apt-get update -q && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    gawk \
    wget \
    git-core \
    diffstat \
    unzip \
    texinfo \
    gcc-multilib \
    build-essential \
    vim \
    chrpath \
    socat \
    sudo \
    cpio \
    apt-utils \
    dnsutils \
    htop \
    iputils-ping \
    locales \
    lsb-core\
    net-tools \
    tmux \
    tzdata \
    python3-distutils \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/* 

RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
RUN locale-gen en_US.UTF-8  

#################################################################
# /root profile

ENV ROOT_BASHRC_PATH /root/.bashrc
WORKDIR /root
RUN sed -ie "s/#force_color_prompt/force_color_prompt/g" ${ROOT_BASHRC_PATH}
RUN echo "PS1='\033[44m\033[01;37mContainer\033[0m \[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" | tee -a ${ROOT_BASHRC_PATH}

#################################################################
# developerグループとユーザーの追加

RUN groupadd  ${GROUPNAME} \
    && useradd -rm -d /home/${USERNAME} -s /bin/bash -g ${GROUPNAME} -u ${ARG_UID} ${USERNAME}  \
    && gpasswd -a ${USERNAME} sudo \
    && echo "${USERNAME}:${USERPASSWD}" | chpasswd \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

#################################################################
# ユーザー切り替え

USER ${USERNAME}

# Support: Your system needs to support the en_US.UTF-8 locale.
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8

ENV HOME_DIR /home/${USERNAME}
ENV BASHRC_PATH ${HOME_DIR}/.bashrc
ENV  YOCTO_WORK_TOP ${HOME_DIR}/reterminal-yocto

# Modify .bashrc
WORKDIR ${HOME_DIR}
RUN sed -ie "s/#force_color_prompt/force_color_prompt/g" ${BASHRC_PATH}
RUN echo "PS1='\033[44m\033[01;37mContainer\033[0m \[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" | tee -a ${BASHRC_PATH}

# Step 2. Create a new working directory and enter it
# Step 3. Create a new directory to add layers and enter it
WORKDIR ${YOCTO_WORK_TOP}/layers

# Step 4. Clone the following GitHub repo
# git clone -b dunfell git://git.yoctoproject.org/poky
WORKDIR ${YOCTO_WORK_TOP}/layers
COPY rfs/poky poky
WORKDIR ${YOCTO_WORK_TOP}/layers/poky
RUN sudo chown -R ${USERNAME}:${GROUPNAME} . \
    && git config --global --add safe.directory ${YOCTO_WORK_TOP}/poky

# Step 5. Clone the following repos
# git clone -b dunfell https://github.com/Seeed-Studio/meta-seeed-cm4.git
# git clone -b master git://git.yoctoproject.org/meta-raspberrypi
# git clone -b dunfell https://github.com/meta-qt5/meta-qt5.git
# git clone -b dunfell https://github.com/openembedded/meta-openembedded.git

WORKDIR ${YOCTO_WORK_TOP}/layers
COPY rfs/meta-seeed-cm4 meta-seeed-cm4
COPY rfs/meta-seeed-cm4 meta-seeed-reterminal
COPY rfs/meta-raspberrypi meta-raspberrypi
COPY rfs/meta-qt5 meta-qt5
COPY rfs/meta-openembedded meta-openembedded

WORKDIR ${YOCTO_WORK_TOP}/layers/meta-seeed-cm4
RUN sudo chown -R ${USERNAME}:${GROUPNAME} . \
    && git config --global --add safe.directory ${YOCTO_WORK_TOP}/layers/meta-seeed-cm4

WORKDIR ${YOCTO_WORK_TOP}/layers/meta-seeed-reterminal
RUN sudo chown -R ${USERNAME}:${GROUPNAME} . \
    && git config --global --add safe.directory ${YOCTO_WORK_TOP}/layers/meta-seeed-reterminal
    

WORKDIR ${YOCTO_WORK_TOP}/layers/meta-raspberrypi
RUN sudo  chown -R ${USERNAME}:${GROUPNAME} . \
    && git config --global --add safe.directory ${YOCTO_WORK_TOP}/layers/meta-raspberrypi

WORKDIR ${YOCTO_WORK_TOP}/layers/meta-qt5
RUN sudo  chown -R ${USERNAME}:${GROUPNAME} . \
    && git config --global --add safe.directory ${YOCTO_WORK_TOP}/layers/meta-qt5

WORKDIR ${YOCTO_WORK_TOP}/layers/meta-openembedded
RUN sudo  chown -R ${USERNAME}:${GROUPNAME} . \
    && git config --global --add safe.directory ${YOCTO_WORK_TOP}/layers/meta-openembedded

# Step 6. Change kernel version from 5.4 to 5.10 in meta-raspberrypi layer
WORKDIR ${YOCTO_WORK_TOP}/layers/meta-raspberrypi
RUN cp -r recipes-kernel/linux/ ../
RUN git checkout dunfell
RUN rm -r recipes-kernel/linux/
RUN mv -f ../linux/ recipes-kernel/

# Step 7. Initialize the build environment

WORKDIR ${YOCTO_WORK_TOP}/layers/poky
RUN . ./oe-init-build-env 
ENV BBPATH ${YOCTO_WORK_TOP}/layers/poky/build
ENV BB_ENV_EXTRAWHITE "ALL_PROXY BBPATH_EXTRA BB_LOGCONFIG BB_NO_NETWORK BB_NUMBER_THREADS BB_SETSCENE_ENFORCE BB_SRCREV_POLICY DISTRO FTPS_PROXY FTP_PROXY GIT_PROXY_COMMAND HTTPS_PROXY HTTP_PROXY MACHINE NO_PROXY PARALLEL_MAKE SCREENDIR SDKMACHINE SOCKS5_PASSWD SOCKS5_USER SSH_AGENT_PID SSH_AUTH_SOCK STAMPS_DIR TCLIBC TCMODE all_proxy ftp_proxy ftps_proxy http_proxy https_proxy no_proxy "
ENV BUILDDIR ${YOCTO_WORK_TOP}/layers/poky/build
ENV PATH ${YOCTO_WORK_TOP}/layers/poky/scripts:${YOCTO_WORK_TOP}/layers/poky/bitbake/bin:${PATH}



# Step 8. Add the layers to the build environment
WORKDIR ${YOCTO_WORK_TOP}/layers/poky/build

RUN sed -ie 's/"qemux86-64"/"seeed-reterminal"/g' ${YOCTO_WORK_TOP}/layers/poky/build/conf/local.conf

RUN bitbake-layers add-layer ../../meta-raspberrypi
# KW --->
# RUN bitbake-layers add-layer ../../meta-seeed-reterminal
RUN bitbake-layers add-layer ../../meta-seeed-cm4
# ---> reterminal
RUN bitbake-layers add-layer ../../meta-qt5
RUN bitbake-layers add-layer ../../meta-openembedded/meta-oe
RUN bitbake-layers add-layer ../../meta-openembedded/meta-python

# # Step 9. Move back to the build directory and execute the following to start compiling
WORKDIR ${YOCTO_WORK_TOP}/layers/poky/build
# RUN MACHINE="seeed-reterminal" bitbake rpi-test-image

