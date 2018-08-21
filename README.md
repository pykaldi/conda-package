Building the package
====================

Easy way:
---------
1. Download anaconda with python3 docker, and run a container
```
docker pull continuumio/anaconda3
docker run -it continuumio/anaconda3
```

2. Install dependencies
```
$ apt-get install git cmake make libatlas3-base
$ conda install conda-build
```

4. Get this repo
```
$ git clone https://github.com/pykaldi/conda-package
```

3. Build the package
```
$ cd conda-package
$ conda-build pykaldi
```
