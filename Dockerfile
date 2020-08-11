# Copyright 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM centos:centos6 as build_pdk

ENV STD_CELL_LIBRARY=sky130_fd_sc_hd

ENV PDK_ROOT=/

ENV OPENROAD=/build/
ENV OPENROADOS=Linux-x86_64

ENV OPENLANE_ROOT=/openLANE_flow

ENV PATH=$OPENLANE_ROOT:$OPENLANE_ROOT/scripts:$OPENROAD/bin:$OPENROAD/bin/Linux-x86_64:$OPENROAD/pdn/scripts:$PATH
ENV LD_LIBRARY_PATH=$OPENROAD/lib:$OPENROAD/lib/Linux-x86_64:$LD_LIBRARY_PATH
ENV MANPATH=$OPENROAD/share/man:$MANPATH

RUN yum install -y https://repo.ius.io/ius-release-el$(rpm -E '%{rhel}').rpm && \
	yum install -y cairo \
	gettext \
	git \
	libffi \
	libgomp \
	libjpeg \
	libSM \
	libXext \
	libXft \
	python36u \
	python36u-pip \
	python36u-tkinter \
	tcl \
	tcllib \
	tk \
	wget \
	Xvfb && \
	yum clean all

RUN alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 60

RUN pip3.6 install --upgrade pip && \
	pip --no-cache-dir install matplotlib && \
	pip --no-cache-dir install jinja2 && \
	pip --no-cache-dir install pandas

COPY docker_build/tar/openroad_tools.tar.gz /
RUN tar -xzf openroad_tools.tar.gz && \
    rm -rf openroad_tools.tar.gz

RUN git clone https://github.com/google/skywater-pdk.git && \
	cd skywater-pdk && \
	git checkout 4e5e318e0cc578090e1ae7d6f2cb1ec99f363120 && \
	git submodule update --init libraries/$STD_CELL_LIBRARY/latest && \
	make $STD_CELL_LIBRARY

RUN git clone https://github.com/efabless/open_pdks.git && \
	cd open_pdks && \
	git checkout rc2 && \
	make && \
	make install-local

FROM centos:centos6

ENV STD_CELL_LIBRARY=sky130_fd_sc_hd

ENV PDK_ROOT=/

ENV OPENROAD=/build/
ENV OPENROADOS=Linux-x86_64

ENV OPENLANE_ROOT=/openLANE_flow

ENV PATH=$OPENLANE_ROOT:$OPENLANE_ROOT/scripts:$OPENROAD/bin:$OPENROAD/bin/Linux-x86_64:$OPENROAD/pdn/scripts:$PATH
ENV LD_LIBRARY_PATH=$OPENROAD/lib:$OPENROAD/lib/Linux-x86_64:$LD_LIBRARY_PATH
ENV MANPATH=$OPENROAD/share/man:$MANPATH

RUN yum install -y https://repo.ius.io/ius-release-el$(rpm -E '%{rhel}').rpm && \
	yum install -y cairo \
	gettext \
	git \
	libffi \
	libgomp \
	libjpeg \
	libSM \
	libXext \
	libXft \
	python36u \
	python36u-pip \
	python36u-tkinter \
	tcl \
	tcllib \
	tk \
	wget \
	Xvfb && \
	yum clean all

RUN alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 60

RUN pip3.6 install --upgrade pip && \
	pip --no-cache-dir install matplotlib && \
	pip --no-cache-dir install jinja2 && \
	pip --no-cache-dir install pandas

COPY docker_build/tar/.tclshrc /root

ADD docker_build/tar/openroad_tools.tar.gz /
ADD docker_build/tar/openLANE_flow.tar.gz $OPENLANE_ROOT
COPY --from=build_pdk $PDK_ROOT/sky130A $PDK_ROOT/sky130A

RUN cd $OPENROAD/OpenDB_python/&& python3 setup.py install
RUN rm -rf $OPENROAD/OpenDB_python

WORKDIR $OPENLANE_ROOT

CMD /bin/bash