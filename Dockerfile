FROM nvcr.io/nvidia/l4t-base:r32.3.1
#Copy qemu to build on x86 host
COPY qemu-aarch64-static /usr/bin

# Change to location of your deb files)
ARG OPENCV_DEBS=opencv-aarch64-deb/opencv-aarch64-deb
ARG SASESP_DEBS=espedge_repos/sas-espedge-125-aarch64_ubuntu_linux_16-apt

RUN mkdir -p /opt/opencv/ && \
    mkdir -p /opt/sas_installfiles/
COPY ${OPENCV_DEBS} /opt/opencv
COPY ${SASESP_DEBS} /opt/sas_installfiles

ENV DEBIAN_FRONTEND=noninteractive

# Install apt packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
	python3-pip \
	python3-setuptools \
	cython3 \
	python3-dev \
	python3-numpy \
	python3-pandas \
	python3-matplotlib \
	python3-sklearn \
	python3-scipy \
	build-essential \
	gfortran \
	git \
	cmake \
	libopenblas-dev \
	liblapack-dev \
	libblas-dev \
	libhdf5-serial-dev \
	hdf5-tools \
	libhdf5-dev \
	zlib1g-dev \
	zip \
	libjpeg8-dev \
	libopenmpi2 \
	openmpi-bin \
	openmpi-common \
	nodejs \
	npm \
	protobuf-compiler \
	libprotoc-dev \
	llvm-9 \
	llvm-9-dev \
        numactl \
        java-common \
	libavcodec-extra57 \
	libavformat57 \
	libqt5core5a \
	libqt5gui5 \
	libqt5opengl5 \
	libqt5test5 \
	libqt5widgets5 \
	libswscale4 \
        graphviz \
    && apt install -f \
    && rm -rf /var/lib/apt/lists/*

### Python pip packages
## Installation
RUN pip3 install wheel && \ 
    pip3 install \
	pybind11 \
	mss \
	git+https://github.com/sassoftware/python-dlpy \
	git+https://github.com/sassoftware/python-esppy \
	git+https://github.com/sassoftware/python-swat \
	ws4py \
	wsaccel \
	websocket-client

# Install OpenCV from .deb files
RUN rm /usr/lib/aarch64-linux-gnu/libGL.so && ln -s /usr/lib/aarch64-linux-gnu/libGL.so.1.0.0 /usr/lib/aarch64-linux-gnu/libGL.so && \
    ln -s /usr/lib/aarch64-linux-gnu/libcudnn.so.7 /usr/lib/aarch64-linux-gnu/libcudnn.so

WORKDIR /opt/opencv
RUN cd /opt/opencv && dpkg -i *.deb

### JupyterLab
## Environment Variables
ENV JUPYTERLAB_PORT=8080
ENV JUPYTERLAB_NBDIR=/data/notebooks
## Installation & Configuration
RUN pip3 install jupyter jupyterlab --verbose
#RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager@2
RUN jupyter lab --generate-config
RUN python3 -c "from notebook.auth.security import set_password; set_password('sas', '/root/.jupyter/jupyter_notebook_config.json')" 

### SAS Event Stream Processing
# Environment Variables
ENV DFESP_HOME=/opt/sas/viya/home/SASEventStreamProcessingEngine/6.2
ENV ESP_PORT=9900
ENV ESP_PUBSUB_PORT=31416
ENV ESP_LOGLEVEL=error
ENV ESP_MAS_THREADS=1
ENV MAS_M2PATH=/opt/sas/viya/home/SASFoundation/misc/embscoreeng/mas2py.py
ENV MAS_PYPATH=/usr/bin/python3
ENV MAS_PYLOG_LEVEL=ERROR
ENV MAS_PYLOG_FILE=/opt/maspylog.txt
ENV DFESP_JAVA_TRUSTSTORE=TEST
ENV SSLCALISTLOC=TEST
ENV ESP_LICENSE_FILE=/data/notebooks/license.txt
# Installation & Configuration
RUN dpkg -i /opt/sas_installfiles/basic/* \
	    /opt/sas_installfiles/analytics/* \
	    /opt/sas_installfiles/astore/* \
	    /opt/sas_installfiles/textanalytics/* \
	    /opt/sas_installfiles/gpu/*

RUN usermod -a -G video root

### Startup Scripts
# Create ESP startup script
RUN echo '#!/bin/bash\n' \
	 'export LD_LIBRARY_PATH=$DFESP_HOME/lib/:/opt/sas/viya/home/SASFoundation/sasexe/:$LD_LIBRARY_PATH \n' \
	 'cp $ESP_LICENSE_FILE /opt/sas/viya/home/SASEventStreamProcessingEngine/6.2/etc/license/license.txt \n' \
         'ln -s /usr/lib/aarch64-linux-gnu/libnvinfer.so.6 /usr/lib/aarch64-linux-gnu/libnvinfer.so.5 \n' \
	 '$DFESP_HOME/bin/dfesp_xml_server -http $ESP_PORT -pubsub $ESP_PUBSUB_PORT -loglevel "esp=$ESP_LOGLEVEL" -mas-threads=$ESP_MAS_THREADS' > /opt/esp_start.sh

# Create Main startup script
RUN echo '#!/bin/bash\n' \
	 '/opt/esp_start.sh & \n' \
	 'jupyter lab --port $JUPYTERLAB_PORT --ip 0.0.0.0 --allow-root --no-browser --NotebookApp.token='' --NotebookApp.password='' --NotebookApp.notebook_dir=$JUPYTERLAB_NBDIR --NotebookApp.allow_origin='*'\n' \
	 'while true \n' \
	 'do \n ' \
         'sleep 3600 \n' \
         'done'> /opt/start.sh

RUN chmod +x /opt/start.sh /opt/esp_start.sh

CMD /opt/start.sh
