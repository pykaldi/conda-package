FROM pykaldi/pykaldi:latest

# Install miniconda to /miniconda
RUN curl -LO https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh &&\
	bash Miniconda3-latest-Linux-x86_64.sh -p /miniconda -b &&\
	rm Miniconda3-latest-Linux-x86_64.sh

ENV PATH=/miniconda/bin:${PATH}
ENV CLIF_MATCHER="/usr/clang/bin/clif-matcher"

RUN conda update -y conda &&\
	conda install -y numpy pyparsing setuptools ninja conda-build

# Install pykaldi into conda
RUN cd /pykaldi &&\
	python setup.py install