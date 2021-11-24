FROM ubuntu:20.04
MAINTAINER Trevor Dolby <tdolby@uk.ibm.com> (@tdolby)

# copied from https://github.com/ot4i/ace-docker/tree/master/experimental/ace-full
# docker build -t ace-full:12.0.2.0-ubuntu -f Dockerfile.ubuntu
# docker build --no-cache -t ace-full:12.0.2.0-ubuntu .

# ARG DOWNLOAD_URL=http://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/integration/12.0.2.0-ACE-LINUX64-DEVELOPER.tar.gz
ARG DOWNLOAD_URL=http://host.docker.internal:7800/12.0.2.0-ACE-LINUX64-DEVELOPER.tar.gz
ARG PRODUCT_LABEL=ace-12.0.2.0

# Prevent errors about having no terminal when using apt-get
ENV DEBIAN_FRONTEND noninteractive

# Install ACE v12.0.2.0 and accept the license
RUN apt-get update && apt-get install -y --no-install-recommends curl && \
    mkdir /opt/ibm && echo Downloading package ${DOWNLOAD_URL} && \
    curl ${DOWNLOAD_URL} | tar zx --directory /opt/ibm && \
    mv /opt/ibm/${PRODUCT_LABEL} /opt/ibm/ace-12 && \
    /opt/ibm/ace-12/ace make registry global accept license deferred

# Configure the system
RUN echo "ACE_12:" > /etc/debian_chroot \
  && echo ". /opt/ibm/ace-12/server/bin/mqsiprofile" >> /root/.bashrc

# mqsicreatebar prereqs; need to run "Xvfb -ac :99 &" and "export DISPLAY=:99"
RUN apt-get -y install libgtk-3-0 libxtst6 libswt-gtk-4-java libswt-gtk-4-jni xvfb && \
  mkdir -p ~/.swt/lib/linux/x86_64 && \
  ln -s /usr/lib/jni/libswt-* ~/.swt/lib/linux/x86_64

# swt-pi4-gtk-4932r18 (Not found in java.library.path)
# swt-pi4-gtk (Not found in java.library.path)
# /root/.swt/lib/linux/x86_64/libswt-pi4-gtk-4932r18.so

# Set BASH_ENV to source mqsiprofile when using docker exec bash -c
ENV BASH_ENV=/opt/ibm/ace-12/server/bin/mqsiprofile

# Accept License, source mqsiprofile and create the ace workdir
RUN su - root -c "export LICENSE=accept && . /opt/ibm/ace-12/server/bin/mqsiprofile && mqsicreateworkdir /root" 

#RUN useradd --uid 1001 --create-home --home-dir /home/aceuser --shell /bin/bash -G mqbrkrs,sudo aceuser \
#  && su - aceuser -c "export LICENSE=accept && . /opt/ibm/ace-12/server/bin/mqsiprofile && mqsicreateworkdir /home/aceuser/ace-server" \
#  && echo ". /opt/ibm/ace-12/server/bin/mqsiprofile" >> /home/aceuser/.bashrc

# aceuser
# USER 1001
# ENTRYPOINT ["bash"]

USER root
RUN echo "Xvfb -ac :100 &" >> /root/.bashrc
RUN echo "export DISPLAY=:100" >> /root/.bashrc
ENTRYPOINT ["bash"]