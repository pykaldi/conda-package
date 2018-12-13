# Environment definition

First, we build a docker image with CentOS 7 and all the dependencies needed to build the package:

```
docker build --tag condapkg_centos7 --build-arg CACHEBUST=$(date +%s) .
```

The build arg is used to force docker to download a new copy of this repo everytime we build the image. 

# Building the conda package
The entrypoint for this docker image is `anaconda_upload.sh`. This script takes as an argument the name of the folder we want to build for and upload to anaconda. For pykaldi:

```
docker run -it --rm -e CONDA_UPLOAD_TOKEN='<TOKEN>' condapkg_centos7 pykaldi
```

And for pykaldi-cpu
```
docker run -it --rm -e CONDA_UPLOAD_TOKEN='<TOKEN>' condapkg_centos7 pykaldi-cpu
```

Token is the token obtained from anaconda.org

## Debugging
To debug the process, we can bypass the docker entrypoint as 
```
docker run -it --rm -e CONDA_UPLOAD_TOKEN='<TOKEN>' --entrypoint bash condapkg_centos7
```
