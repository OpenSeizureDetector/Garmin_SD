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
ENV CONNECT_IQ_HOME /connectiq
RUN mkdir -p ${CONNECT_IQ_HOME}

# hardcoding the version for now
ENV CONNECT_IQ_VERSION 4.1.5

# download the SDK
#COPY downloader.sh /root/downloader.sh
#RUN /root/downloader.sh $CONNECT_IQ_HOME $CONNECT_IQ_VERSION

# download the SDK Manager
COPY download_sdk.sh /root/download_sdk.sh
RUN /root/download_sdk.sh $CONNECT_IQ_HOME


# manage device files
# TODO find a way to download device bits from Garmin website
#COPY devices.zip /tmp/devices.zip
#RUN unzip /tmp/devices.zip -d /connectiq-devices

#FROM ubuntu:jammy as tester

# install required dependencies
# libwebkit2gtk-4.0-37, libusb-1.0-0, libsm6 and xvfb are required by the simulator
# openssl is required to create a fake certificate
#RUN apt-get update && apt-get -y install \
#	openjdk-17-jre-headless \
#	libwebkit2gtk-4.0-37 \
#	libusb-1.0-0 \
#	libsm6 \
#	xvfb \
#	git \
#	&& apt-get clean

# prepare ConnectIQ home folder
#ENV CONNECT_IQ_HOME /connectiq
#RUN mkdir -p ${CONNECT_IQ_HOME}

# retrieve downloaded SDK from the downloader image
#COPY --from=downloader /connectiq /connectiq

# add ConnectIQ bin folder to the path
ENV PATH ${PATH}:${CONNECT_IQ_HOME}/bin

# manage device files
# devices bits must be put in /root/.Garmin/ConnectIQ/Devices/ because this path is hard-coded in the compiler and in the simulator!
# there is an undocumented option named "--override-devices-json" in the compiler class "com.garmin.monkeybrains.Monkeybrains.class"
# this option allows to specify the paths where the devices bits are stored
# unfortunately there is no such option for the simulator
#RUN mkdir -p /root/.Garmin/ConnectIQ/Devices
# retrieve devices files from the downloader image
#COPY --from=downloader /connectiq-devices /root/.Garmin/ConnectIQ/Devices

# copy custom tester script
#COPY tester.sh "${CONNECT_IQ_HOME}/bin/tester.sh"

# do not use ${CONNECT_IQ_HOME} here because variable substitution won't work
#ENTRYPOINT [ "/bin/bash", "/connectiq/bin/tester.sh" ]
