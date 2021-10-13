# ARM Build environment using Segger ARM Compiler

# Base Image
FROM ubuntu:18.04

# Metadata
LABEL MAINTAINER Dermot Murphy <dermot.murphy@canembed.com> Name=arm-environ

# Arguments (Segger Compiler)
ARG SEGGER_EMSTUDIO_DL=https://www.segger.com/downloads/embedded-studio/Setup_EmbeddedStudio_ARM_v416_linux_x64.tar.gz

# Arguments (Nordic SDK)
ARG NORDIC_SDK_DL=https://developer.nordicsemi.com/nRF5_SDK/nRF5_SDK_v15.x.x/nRF5_SDK_15.2.0_9412b96.zip

# Arguments (Nordic tools)
#ARG NORDIC_TOOLS_DL=https://www.nordicsemi.com/-/media/Software-and-other-downloads/Desktop-software/nRF-command-line-tools/sw/Versions-10-x-x/10-14-0/nRF-Command-Line-Tools_10_14_0_Linux64.zip
ARG NORDIC_TOOLS_DL=https://github.com/NordicSemiconductor/pc-nrfutil/releases/download/v6.1.2/nrfutil-6.1.2.tar.gz

# Arguments (ARM GNU Compiler)
ARG ARM_COMPILER_DL=https://developer.arm.com/-/media/Files/downloads/gnu-rm/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2

# Arguments (AStyle)
ARG ASTYLE_DL=https://downloads.sourceforge.net/project/astyle/astyle/astyle%203.1/astyle_3.1_linux.tar.gz

# Basic development environment
RUN	apt-get update && \
	apt-get install -y libx11-6 libfreetype6 libxrender1 libfontconfig1 libxext6 libc6-dev-i386 libc6-dev-i386-amd64-cross
RUN	apt-get install -y zip curl wget unzip		&& \
	apt-get install -y make				&& \
	apt-get install -y git 				&& \
	apt-get install -y subversion			&& \
	apt-get install -y doxygen graphviz		&& \
	apt-get install -y gcc 				&& \
	apt-get install -y python  python-pip 		&& \
	apt-get install -y cpio libncurses5		&& \
	apt-get install -y ninja-build			&& \
	apt-get install -y ruby-full			&& \
	pip install gcovr				&& \
	gem install rake ceedling

# CMake (Get the latest release version as Ubuntu has an older version)
# Details at: https://apt.kitware.com/
RUN	apt-get install -y apt-transport-https wget	&&\
	wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null 	 && \
	echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ bionic main' | tee /etc/apt/sources.list.d/kitware.list >/dev/null && \
	apt-get update					&& \
	rm /usr/share/keyrings/kitware-archive-keyring.gpg 	&& \
	apt-get install -y kitware-archive-keyring	&& \
	apt-get install -y cmake

# GCC ARM Compiler
RUN	mkdir -p /compilers/gcc-arm-none-eabi	 	&& \
	cd /compilers/gcc-arm-none-eabi 		&& \
	wget $ARM_COMPILER_DL -O gcc-arm-none-eabi.tar.bz2 	&& \
	tar -xvf gcc-arm-none-eabi.tar.bz2 --strip-components 1 && \
	rm gcc-arm-none-eabi.tar.bz2
ENV PATH=/compilers/gcc-arm-none-eabi/bin:${PATH}

# AStyle
RUN	mkdir -p /tools/astyle				&& \
	cd /tools/astyle				&& \
	wget  $ASTYLE_DL -O astyle.tar.gz		&& \
	tar -xvf astyle.tar.gz --strip-components 1	&& \
	cd build					&& \
	cmake .. -GNinja				&& \
	cmake --build .					&& \
	cd ..						&& \
	mkdir bin					&& \
	cp build/astyle bin/astyle			&& \
	rm astyle.tar.gz			
ENV PATH="/tools/astyle/bin:${PATH}"

# Segger Embedded Studio Compiler
RUN	mkdir -p /compilers/segger			&& \
	cd /tmp 					&& \
	wget $SEGGER_EMSTUDIO_DL -qO /tmp/ses.tar.gz	&& \
	tar -zxvf /tmp/ses.tar.gz 			&& \
	printf 'yes\n' | DISPLAY=:1 $(find arm_segger_* -name "install_segger*") --copy-files-to /compilers/segger 	&& \
	rm ses.tar.gz 					&& \
	rm -rf arm_segger_embedded_studio_*
ENV PATH=/compilers/segger/bin:$PATH

# Nordic SDK
RUN	mkdir -p /nordic/sdk 				&& \
	cd /nordic/sdk 					&& \
	wget $NORDIC_SDK_DL -qO nRF5-SDK.zip 		&& \
	unzip nRF5-SDK.zip 				&& \
	rm nRF5-SDK.zip

# Nordic Tools
RUN	mkdir -p /nordic/nrftools 			&& \
	cd /nordic/nrftools 				&& \
	wget $NORDIC_TOOLS_DL -O nrftools.tar.gz	&& \
	tar -xvf nrftools.tar.gz
ENV PATH=/nordic/nrftools/nrf-command-line-tools/bin:$PATH

# Working directory
#WORKDIR /data
#VOLUME ["/data"]

# Entry point (which cannot be overriden on the command line but can be appended to)
#ENTRYPOINT cd /data

# Default command (which can be overridden on the command line)
CMD ["bash"]