FROM ubuntu:jammy as downloader
ARG DEBIAN_FRONTEND=noninteractive

LABEL org.opencontainers.image.authors="matthieu.corageoud@gmail.com"
LABEL org.opencontainers.image.version="2.1.1"
LABEL org.opencontainers.image.description="ConnectIQ tester"
LABEL org.opencontainers.image.source=https://github.com/matco/connectiq-tester

# install required dependencies
# curl, jq, wget, unzip are required to download the SDK
RUN apt-get update && apt-get -y install \
	curl \
	jq \
	wget \
	unzip \
	git \
	libsecret-tools \
	libxkbcommon-tools \
	libxxf86vm1 \ 
	libsm6 \
	libatk1.0-0 \
	libgdk3.0-cil \
	libwebkit2gtk-4.0-37 \
	libusb-1.0-0 \
	openjdk-8-jre \
	&& apt-get clean

# prepare ConnectIQ home folder
ENV CONNECT_IQ_HOME /root/.Garmin/ConnectIQ
RUN mkdir -p ${CONNECT_IQ_HOME}

# hardcoding the version for now
ENV CONNECT_IQ_VERSION 6.4.2

# download the SDK
COPY downloader.sh /root/downloader.sh
RUN /root/downloader.sh $CONNECT_IQ_HOME $CONNECT_IQ_VERSION

# download the SDK Manager
COPY download_sdk.sh /root/download_sdk.sh
RUN /root/download_sdk.sh $CONNECT_IQ_HOME


# manage device files
# TODO find a way to download device bits from Garmin website
COPY devices.zip /tmp/devices.zip
RUN unzip /tmp/devices.zip -d ${CONNECT_IQ_HOME}/Devices

# manage fonts files
COPY fonts.zip /tmp/fonts.zip
RUN unzip /tmp/fonts.zip -d ${CONNECT_IQ_HOME}/Fonts




# add ConnectIQ bin folder to the path
ENV PATH ${PATH}:${CONNECT_IQ_HOME}/bin
