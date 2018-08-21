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

Not so easy way
---------------
1. Create a conda environment
```
conda create -n pykaldipkg python=3.5
conda activate pykaldipkg
```

2. Install conda-build
```
conda install conda-build
```

3. Build the package
```
conda-build pykaldi
```

On success, this will create a .tar.bz2 file in the environment folder (e.g., /home/victor/miniconda3/envs/pykaldipkg/conda-bld/linux-64/pykaldi-0.0.9-hf484d3e_0.tar.bz2). Take note of the location of this file.

4. Install pykaldi conda package
```
conda install [tar.bz2 file]
```

5. (Opt) Test it
