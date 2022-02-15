# ARM Build environment using Segger ARM Compiler

# Base Image
FROM ubuntu:20.04

# Metadata
LABEL MAINTAINER Dermot Murphy <dermot.murphy@canembed.com> Name=arm-environ

# Arguments (Segger Compiler)
ARG SEGGER_VERSION=416
ARG SEGGER_EMSTUDIO_URL=https://www.segger.com/downloads/embedded-studio/Setup_EmbeddedStudio_ARM_v${SEGGER_VERSION}_linux_x64.tar.gz

# Arguments (Nordic SDK)
ARG NORDIC_SDK_VER_MAJOR=15
ARG NORDIC_SDK_VER_MINOR=2
ARG NORDIC_SDK_VER_PATCH=0
ARG NORDIC_SDK_VER_CRC=9412b96
ARG NORDIC_SDK_FILENAME=nRF5_SDK_${NORDIC_SDK_VER_MAJOR}.${NORDIC_SDK_VER_MINOR}.${NORDIC_SDK_VER_PATCH}_${NORDIC_SDK_VER_CRC}.zip
ARG NORDIC_SDK_ROOT=https://developer.nordicsemi.com/nRF5_SDK/nRF5_SDK_v${NORDIC_SDK_VER_MAJOR}.x.x
ARG NORDIC_SDK_URL=${NORDIC_SDK_ROOT}/${NORDIC_SDK_FILENAME}
ARG NORDIC_SDK_TARGET=/nordic/sdk_${NORDIC_SDK_VER_MAJOR}.${NORDIC_SDK_VER_MINOR}.${NORDIC_SDK_VER_PATCH}

# Arguments (Nordic tools)
ARG NORDIC_TOOLS_VER_MAJOR=10
ARG NORDIC_TOOLS_VER_MINOR=14
ARG NORDIC_TOOLS_VER_PATCH=0
ARG NORDIC_TOOLS_FILENAME=nRF-Command-Line-Tools_${NORDIC_TOOLS_VER_MAJOR}_${NORDIC_TOOLS_VER_MINOR}_${NORDIC_TOOLS_VER_PATCH}_Linux64.zip
ARG NORDIC_TOOLS_ROOT=https://www.nordicsemi.com/-/media/Software-and-other-downloads/Desktop-software/nRF-command-line-tools/sw/Versions-${NORDIC_TOOLS_VER_MAJOR}-x-x/${NORDIC_TOOLS_VER_MAJOR}-${NORDIC_TOOLS_VER_MINOR}-${NORDIC_TOOLS_VER_PATCH}
ARG NORDIC_TOOLS_URL=${NORDIC_TOOLS_ROOT}/${NORDIC_TOOLS_FILENAME}
ARG NORDIC_TOOLS_TARGET=/nordic/nrftools

# Arguments (Nordic utils)
ARG NORDIC_UTIL_REPO=https://github.com/NordicSemiconductor/pc-nrfutil.git
ARG NORDIC_UTIL_TARGET=/nordic/nrfutil

# Arguments (ARM GNU Compiler)
ARG ARM_COMPILER_VER_MAJOR=10
ARG ARM_COMPILER_VER_MINOR=2020
ARG ARM_COMPILER_VER_PATCH=q4
ARG ARM_COMPILER_FILENAME=gcc-arm-none-eabi-${ARM_COMPILER_VER_MAJOR}-${ARM_COMPILER_VER_MINOR}-${ARM_COMPILER_VER_PATCH}-major-x86_64-linux.tar.bz2
ARG ARM_COMPILER_ROOT=https://developer.arm.com/-/media/Files/downloads/gnu-rm/${ARM_COMPILER_VER_MAJOR}-${ARM_COMPILER_VER_MINOR}${ARM_COMPILER_VER_PATCH}
ARG ARM_COMPILER_URL=${ARM_COMPILER_ROOT}/${ARM_COMPILER_FILENAME}
ARG ARM_COMPILER_TARGET=/gcc-arm-none-eabi

# Arguments (AStyle)
ARG ASTYLE_VER_MAJOR=3
ARG ASTYLE_VER_MINOR=1
ARG ASTYLE_FILENAME=astyle_${ASTYLE_VER_MAJOR}.${ASTYLE_VER_MINOR}_linux.tar.gz
ARG ASTYLE_ROOT=https://downloads.sourceforge.net/project/astyle/astyle/astyle%20${ASTYLE_VER_MAJOR}.${ASTYLE_VER_MINOR}
ARG ASTYLE_URL=${ASTYLE_ROOT}/${ASTYLE_FILENAME}
ARG ASTYLE_TARGET=/astyle

# This is needed on Ubuntu 20.04 to ensure doxygen and graphviz install without causing Ubuntu to ask for a geographical time zone region
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/London

# Basic development environment
ENV RUNNING=BASIC
RUN	apt-get update && \
	apt-get install -y libx11-6 libfreetype6 libxrender1 libfontconfig1 libxext6 libc6-dev-i386 libc6-dev-i386-amd64-cross
RUN	apt-get install -y zip curl wget unzip			&& \
	apt-get install -y make					&& \
	apt-get install -y git 					&& \
	apt-get install -y subversion
	
RUN	apt-get install -y doxygen graphviz

RUN	apt-get install -y gcc					&& \
	apt-get install -y cpio libncurses5			&& \
	apt-get install -y ninja-build

# Python 3	
RUN	apt-get install -y python3 python3-pip

# Ceedling
ENV RUNNING=CEEDLING
RUN	apt-get install -y ruby-full				&& \
	gem install rake ceedling

# Gcovr
ENV RUNNING=GCOVR
RUN	pip install gcovr

# CMake (Get the latest release version as Ubuntu has an older version)
# Details at: https://apt.kitware.com/
ENV RUNNING=CMAKE
RUN	apt-get install -y apt-transport-https wget		&&\
	wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null 	 && \
	echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ bionic main' | tee /etc/apt/sources.list.d/kitware.list >/dev/null && \
	apt-get update						&& \
	rm /usr/share/keyrings/kitware-archive-keyring.gpg 	&& \
	apt-get install -y kitware-archive-keyring		&& \
	apt-get install -y cmake

# GCC ARM Compiler
ENV RUNNING=ARM
RUN	mkdir -p ${ARM_COMPILER_TARGET}	 			&& \
	cd ${ARM_COMPILER_TARGET} 				&& \
	wget ${ARM_COMPILER_URL} -O gcc-arm-none-eabi.tar.bz2 	&& \
	tar -xvf gcc-arm-none-eabi.tar.bz2 --strip-components 1 && \
	rm gcc-arm-none-eabi.tar.bz2
ENV PATH=${ARM_COMPILER_TARGET}/bin:${PATH}

# AStyle
ENV RUNNING=ASTYLE
RUN	mkdir -p ${ASTYLE_TARGET}				&& \
	cd ${ASTYLE_TARGET}					&& \
	wget  ${ASTYLE_URL} -O astyle.tar.gz			&& \
	tar -xvf astyle.tar.gz --strip-components 1		&& \
	cd build						&& \
	cmake .. -GNinja					&& \
	cmake --build .						&& \
	cd ..							&& \
	mkdir bin						&& \
	cp build/astyle bin/astyle				&& \
	rm astyle.tar.gz					&& \
	rm -rf build
ENV PATH="${ASTYLE_TARGET}/bin:${PATH}"

# Segger Embedded Studio Compiler
ENV RUNNING=SEGGER
RUN	mkdir -p /ses						&& \
	cd /tmp 						&& \
	wget ${SEGGER_EMSTUDIO_URL} -qO /tmp/ses.tar.gz		&& \
	tar -zxvf /tmp/ses.tar.gz 				&& \
	printf 'yes\n' | DISPLAY=:1 $(find arm_segger_* -name "install_segger*") --copy-files-to /ses 	&& \
	rm ses.tar.gz 						&& \
	rm -rf arm_segger_embedded_studio_*
ENV PATH=$PATH:/ses/bin

# Nordic SDK
ENV RUNNING=NORDIC_SDK
RUN	mkdir -p ${NORDIC_SDK_TARGET}				&& \
	cd ${NORDIC_SDK_TARGET}					&& \
	wget ${NORDIC_SDK_URL} -qO nRF5-SDK.zip 		&& \
	unzip nRF5-SDK.zip 					&& \
	rm nRF5-SDK.zip

# Nordic Tools (mergehex)
ENV RUNNING=NORDIC_TOOLS
RUN	mkdir -p ${NORDIC_TOOLS_TARGET} 			&& \
	cd ${NORDIC_TOOLS_TARGET} 				&& \
	wget ${NORDIC_TOOLS_URL} -O nrftools.zip		&& \
	cd ${NORDIC_TOOLS_TARGET} 				&& \
	unzip -j nrftools.zip					&& \
	rm nrftools.zip						&& \
	unzip *.zip						&& \
	tar -zxvf *.gz						&& \
	tar -zxvf *.tgz						&& \
	rm -rf *.deb						&& \
	rm -rf *.zip						&& \
	rm -rf *.gz						&& \
	rm -rf *.tgz
ENV PATH=${NORDIC_TOOLS_TARGET}/nrf-command-line-tools/bin:$PATH

# Nordic nRFUtil (to build an OTA package)
# nrfutil is compiled into an executable located at /usr/local/bin
# which is already on the path
ENV RUNNING=NORDIC_UTIL
RUN	mkdir -p ${NORDIC_UTIL_TARGET}				&& \
	cd ${NORDIC_UTIL_TARGET}				&& \
	apt-get update						&& \
	apt-get install -y python3 python3-pip 			&& \
	export PYI_STATIC_ZLIB=1				&& \
	pip3 install pyinstaller				&& \
	git clone ${NORDIC_UTIL_REPO}				&& \
	export LC_ALL=C.UTF-8					&& \
	export LANG=C.UTF-8					&& \
	cd pc-nrfutil						&& \
	python3 setup.py install				&& \
	nrfutil version

# Working directory
#WORKDIR /data
#VOLUME ["/data"]

# Entry point (which cannot be overriden on the command line but can be appended to)
#ENTRYPOINT cd /data

# Default command (which can be overridden on the command line)
CMD ["bash"]