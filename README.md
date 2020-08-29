# SAS Event Stream Processing on Edge Docker Container with GPU acceleration (NVIDIA Jetson TX2)

This repository provides build instructions to create your own SAS Event Stream Processing on Edge Docker Container with GPU acceleration.
Note that this repository is for NVIDIA Jetson TX2 devices, not x64 devices.

If you are looking for the X64 container please visit my other [GitHub repository](https://github.com/Mentos05/SAS_ESP_GPU).

### Overview
SAS Event Stream Processing on Edge already offers the possibility to be installed as a Docker container. So, why does this repository exist?
Looking at the official [documentation](https://go.documentation.sas.com/?docsetId=dplyesp0phy0lax&docsetTarget=p1rcii2jo7dt9yn1qr1upedc0y3w.htm&docsetVersion=6.2&locale=en) you will notice that the Docker image does not support GPU acceleration.

However GPU acceleration is needed or at least recommended if you want to work with deep learning.
For this reason I decided to share my work of creating GPU accelerated for SAS Event Stream Processing.

I mainly use deep learning for Computer Vision - so we are also installing [OpenCV](https://github.com/opencv/opencv) in our container.

Please note:
This repository is privately owned by me. Don't expect any official support for the work provided here.

### Requirements
* Valid SAS Event Stream Processing license file (tested with SAS Event Stream Processing 6.2)
* x64 machine running Ubuntu (tested with Ubuntu 18.04)
* [NVIDIA Jetson TX2](https://developer.nvidia.com/embedded/jetson-tx2)
* [NVIDIA Jetpack](https://developer.nvidia.com/jetpack-43-archive) (tested with Jetpack 4.3)
* [NVIDIA Container Runtime on Jetson](https://github.com/NVIDIA/nvidia-docker/wiki/NVIDIA-Container-Runtime-on-Jetson)

### Container Setup on X64 machine
1. Pull this repository<br>
```
git clone https://github.com/Mentos05/SAS_ESP_JETSON_GPU.git
cd SAS_ESP_JETSON_GPU
```
2. Copy your deployment data file into the repository folder (usually named: SAS_Viya_deployment_data.zip)
```
cp /path/to/your/SAS_Viya_deployment_data.zip .
```
3. Run buildContainer.sh. The script will download all required files and build the container.
```
bash buildContainer.sh
```

### Customize your installation (Optional)
The buildContainer.sh script accepts user variables.<br>
Append them to buildContainer.sh with --variable=value<br>
Example:<br>
```
bash buildContainer.sh --sas_deployment_data=mydeploymentdata.zip
```

| Variable | Description | Default |
| ------ | ------ | ------ |
| sas_deployment_data | Name of your SAS deployment data file | SAS_Viya_deployment_data.zip |
| sas_mirrormanager_download_url | URL for SAS Mirror Manager | https://support.sas.com/installation/viya/35/sas-mirror-manager/lax/mirrormgr-linux.tgz |
| sas_mirrorextensions_download_url | URL for SAS Mirror Manager Extension | https://support.sas.com/installation/viya/35/sas-edge-extension/sas-edge-extension.tgz |
| sas_software_repository | Name of the SAS software repository | sas-espedge-125-aarch64_ubuntu_linux_16-apt |
| qemu_file | Path of your Qemu binary | /usr/bin/qemu-aarch64-static |
| container_name | Docker container name | esp_gpu |
| container_tag | Docker container tag | 6_2_jetson |
| container_build | Build container | YES |
| container_push | Push container to repository | NO |

### Run Container
First, transfer the container to your NVIDIA Jetson TX2. (e.g. via your docker repository).<br>

On your NVIDIA Jetson TX2 use docker run and specify nvidia runtime:
```
docker run -it --runtime nvidia --net=host esp_gpu:6_2_jetson
```

In many cases you want to extend your run call with additional variables to configure the container.

| Variable | Description | Default |
| ------ | ------ | ------ |
| ESP_PORT | ESP -port option | 9900 |
| ESP_PUBSUB_PORT | ESP -pubsub option | 31416 |
| ESP_LOGLEVEL | ESP -loglevel option | error |
| ESP_MAS_THREADS | MAS Threads | 1 |
| MAS_PYLOG_LEVEL | MAS logging level | ERROR |
| MAS_PYLOG_FILE | MAS logfile location | /opt/maspylog.txt |
| JUPYTERLAB_PORT | JupyterLab port | 8080 |
| JUPYTERLAB_NBDIR | JupyterLab notebook directory | /data/notebooks/ |

Example: This will run the ESP server on port 12345.

```
docker run -it --runtime nvidia --net=host -e ESP_PORT 12345 esp_gpu:6_2_jetson
```

### Access Jupyter Lab
Open the following URL in your browser:<br>
http://localhost:8080

### Whats next?
Connect to your container, e.g. via [SAS ESPPy](https://github.com/sassoftware/python-esppy).<br>
Your container is running on port 9900 by default.
```
import esppy
esp = esppy.ESP(hostname='http://localhost:9900')
```

### Jupyter Lab (Python Environment)
Some of the Python packages installed are:<br>

| Package | Description |
| ------ | ------ |
| SAS SWAT | [SAS SWAT](https://github.com/sassoftware/python-swat) |
| SAS DLPy | [SAS DLPy](https://github.com/sassoftware/python-dlpy) | 
| SAS ESPPy | [SAS ESPPy](https://github.com/sassoftware/python-esppy) |
| OpenCV | [OpenCV](https://github.com/opencv/opencv) |

For a full list have a look in the Dockerfile.

### Share ressources with your container
If you want to share ressources with your container, e.g. USB webcam, you can do so by adapting your docker run command.<br>
To share devices, e.g. your webcam, use:
```
docker run --device=/dev/video0:/dev/video0 --net=host esp_gpu:6_2_jetson
```
To share a folder, e.g. with additional data like models, projects, etc. use:
```
docker run -v folder-on-host:folder-on-container --net=host esp_gpu:6_2_jetson
```

Example: For my needs I usually start my container with the following command to share my local notebooks, my USB webcam, host networking interface and to allow GUI applications (e.g. OpenCV).<br>
```
xhost +

docker run -it --runtime nvidia --privileged=true \
           --net=host --ipc=host \
           -v /home/michael/Development/github.com/:/data/notebooks \
           -v /tmp/.X11-unix:/tmp/.X11-unix \
           -v /var/run/dbus:/var/run/dbus \
           --device=/dev/video0:/dev/video0 \
           -e DISPLAY=$DISPLAY \
           esp_gpu:6_2_jetson
```

### Run GUI applications inside your Docker container
I am using OpenCV very often to display the scored images from ESP. To allow OpenCV to access your hosts display you'll have to allow access to your X server.
To do this simply type `xhost +` on your host system.
Additionally you'll have to provide some information to your container by adding the following statements to your run-command:<br>
```
-e DISPLAY=$DISPLAY
-v /tmp/.X11-unix:/tmp/.X11-unix
```

### Private Repository
Please Note: This is my private repository and not an official SAS repository.<br>
If you are looking for official SAS repositories, please go to:
* [SAS Software Repository](https://github.com/sassoftware/)
* [SAS Scripting Wrapper for Analytics Transfer (SWAT)](https://github.com/sassoftware/python-swat)
* [SAS Viya Deep Learning API for Python](https://github.com/sassoftware/python-dlpy)
* [SAS Event Stream Processing Python Interface](https://github.com/sassoftware/python-esppy)

### Contact
If you like to discuss how deep learning can be applied to your problems, you're of course free to contact me.<br>

| Channel | Adress |
| ------ | ------ |
| Email Work | michael.gorkow@sas.com |
| Email Private | michaelgorkow@gmail.com |
| LinkedIn | [LinkedIn Profile](https://www.linkedin.com/in/michael-gorkow-08353678/) |
| Twitter | [Twitter Profile](https://twitter.com/GorkowMichael) |
