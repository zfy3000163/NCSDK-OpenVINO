#FROM zfy3000/ubotica:v1.0 
FROM ubuntu:16.04

##install the openvino
ARG DOWNLOAD_LINK=http://registrationcenter-download.intel.com/akdlm/irc_nas/15382/l_openvino_toolkit_p_2019.1.094.tgz
ARG INSTALL_DIR=/opt/intel/openvino
ARG TEMP_DIR=/tmp/openvino_installer
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    cpio \
    sudo \
    lsb-release && \
    rm -rf /var/lib/apt/lists/*
RUN mkdir -p $TEMP_DIR && cd $TEMP_DIR && \
    wget -c $DOWNLOAD_LINK && \
    tar xf l_openvino_toolkit*.tgz && \
    cd l_openvino_toolkit* && \
    sed -i 's/decline/accept/g' silent.cfg && \
    ./install.sh -s silent.cfg && \
    rm -rf $TEMP_DIR
RUN chmod 777 $INSTALL_DIR/install_dependencies/install_openvino_dependencies.sh 
RUN $INSTALL_DIR/install_dependencies/install_openvino_dependencies.sh
# build Inference Engine samples
RUN mkdir $INSTALL_DIR/deployment_tools/inference_engine/samples/build && cd $INSTALL_DIR/deployment_tools/inference_engine/samples/build && \
    sudo /bin/bash -c "source $INSTALL_DIR/bin/setupvars.sh && cmake .. && make -j4"

##install libusb
RUN apt-get install -y unzip && apt-get install -y autoconf && \
   apt-get install -y libtool && apt-get install -y python3 && apt-get install -y python3-pip && \
   cd /tmp/ && \
   wget https://github.com/libusb/libusb/archive/v1.0.22.zip && \
   unzip v1.0.22.zip && cd libusb-1.0.22 && \
   ./bootstrap.sh && \
   ./configure --disable-udev --enable-shared && \
   make -j4 && make install && \
   rm -rf /tmp/*

RUN apt-get install -y  libprotobuf-dev libleveldb-dev libsnappy-dev libopencv-dev libhdf5-serial-dev protobuf-compiler && \
	apt-get install -y --no-install-recommends libboost-all-dev && apt-get install -y git openssh-server vim && \
	pip3 install -U pip  && mkdir -p /workspace

##install ncsdk
WORKDIR /workspace
RUN apt-get install -y \
    lsb-release \
    build-essential \
    sed \
    sudo \
    udev && \
    apt-get clean && mkdir -p /tmp/workspace && git clone -b v2.10.01.01 https://github.com/movidius/ncsdk.git ncsdk && \
    apt-get install -y libdmtx0a 

WORKDIR /workspace/ncsdk
RUN chmod +x *.sh && sync
RUN export PATH=$PATH:/bin:/usr/bin ; ./install-opencv.sh
RUN export PATH=$PATH:/bin:/usr/bin ; ./install.sh && rm -rf /workspace/ncsdk

##other lib
RUN pip3 install paho-mqtt && pip3 install oslo_utils && pip3 install future && pip3 install pylibdmtx && \
	pip3 install sklearn && pip3 install joblib 

COPY ubotica /opt/ubotica/ 

WORKDIR /opt/ubotica/test 

CMD ["/bin/bash", "-c", "while true;do sleep 30;/opt/intel/openvino_2019.1.094/bin/setupvars.sh;done;"]

#CMD ["python", "TestSCContent.py"]
