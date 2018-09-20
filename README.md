Building the package
====================

1. Install conda-build and anaconda-client (for uploading)

```
conda install conda-build anaconda-client
```

2. Clone this repository

3. From the root of this repo, build each package with

```
conda build pykaldi
```

or 

```
conda build pykaldi-cpu
```

4. (Opt) Upload it to anaconda.org

```
anaconda upload -u Pykaldi [output.bzip]
```

5. (Opt) Test it
