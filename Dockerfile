FROM ubuntu:focal

USER root

ARG tempDir=/tmp/zowe
ARG sshEnv=/etc/profile.d/npm_setup.sh
ARG bashEnv=/etc/bash.bashrc
ARG scriptsDir=/usr/local/bin/
ARG loginFile=pam.d.config

ENV ENV=${bashEnv}
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV DEFAULT_NODE_VERSION=16.6.2
ENV ZOWE_APP_LOG_LEVEL=ERROR
ENV ZOWE_IMPERATIVE_LOG_LEVEL=ERROR

RUN apt-get update -qqy \
  && apt-get -qqy install \
    locales \
    sudo \
    wget \
    unzip \
    zip \
    git \
    curl \
    sshpass \
    libxss1 \
    vim \
    nano

# Upgrade packages on image
# Preparations for sshd
RUN locale-gen en_US.UTF-8 &&\
    apt-get -q update &&\
    DEBIAN_FRONTEND="noninteractive" apt-get -q upgrade -y -o Dpkg::Options::="--force-confnew" --no-install-recommends &&\
    DEBIAN_FRONTEND="noninteractive" apt-get -q install -y -o Dpkg::Options::="--force-confnew" --no-install-recommends gnome-keyring libsecret-1-dev dbus-x11 openssh-server software-properties-common &&\
    apt-get -q autoremove &&\
    sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd &&\
    mkdir -p /var/run/sshd

RUN add-apt-repository -y ppa:openjdk-r/ppa &&\
    apt-get -q update

# Add Zowe user
RUN sudo useradd zowe --shell /bin/bash --create-home \
  && sudo usermod -a -G sudo zowe \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && echo 'zowe:zowe' | chpasswd

# Fix OpenSSL problems with TLS 1.2
COPY openssl.cnf /etc/ssl/openssl.cnf

# Install Node, nvm, plugin prereqs
RUN curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
RUN apt-get install -y nodejs expect build-essential

RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
RUN groupadd npmusers && usermod -aG npmusers zowe

# Also install nvm for user zowe
USER zowe
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash

USER root

# Get rid of dash and use bash instead
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

# First move the template file over
RUN mkdir ${tempDir}
COPY env.bashrc ${tempDir}/env.bashrc

# Create a properties file that is used for all bash sessions on the machine
# Add the environment setup before the exit line in the global bashrc file
RUN sed -i -e "/# If not running interactively, don't do anything/r ${tempDir}/env.bashrc" -e //N ${bashEnv}

# Copy the setup script and node/nvm scripts for execution (allow anyone to run them)
COPY docker-entrypoint.sh ${scriptsDir}
COPY install_node.sh ${scriptsDir}

# Install Node
RUN install_node.sh $DEFAULT_NODE_VERSION
RUN su -c "install_node.sh $DEFAULT_NODE_VERSION" - zowe

# Copy the PAM configuration options to allow auto unlocking of the gnome keyring
COPY ${loginFile} ${tempDir}/${loginFile}

# Enable unlocking for ssh
RUN cat ${tempDir}/${loginFile}>>/etc/pam.d/sshd

# Enable unlocking for regular login
RUN cat ${tempDir}/${loginFile}>>/etc/pam.d/login

# Copy the profile script 
COPY dbus_start ${tempDir}/dbus_start

# Create a shell file that applies the configuration for sessions.
# Also enable dbus for ssh and most other native shells
RUN touch ${sshEnv} \
    && echo '#!bin/sh'>>${sshEnv} \
    && cat ${tempDir}/env.bashrc>>${sshEnv} \
    && cat ${tempDir}/dbus_start>>${sshEnv}

# Enable for all bash profiles
# Add the dbus launch before exiting when not running interactively
RUN sed -i -e "/# If not running interactively, don't do anything/r ${tempDir}/dbus_start" -e //N ${bashEnv}

# Auto unlock keyring on login
RUN printf "\nif test -z \"\$SSH_CONNECTION\"; then\n\techo zowe | gnome-keyring-daemon --unlock --components=secrets > /dev/null\nfi\n" >> /home/zowe/.bashrc

COPY install_zowe.sh ${scriptsDir}

# Setup Zowe Daemon
RUN wget https://github.com/zowe/zowe-cli/releases/download/native-v0.2.1/zowex-linux.tgz
RUN tar -xzf zowex-linux.tgz
RUN rm -rf zowex-linux.tgz
RUN chmod +rx zowex
RUN mv zowex ${scriptsDir}

# Quick script to start daemon
COPY start-zowe-daemon ${scriptsDir}
COPY start-zowe-daemon-2 ${scriptsDir}
COPY bashrc-update.txt ${scriptsDir}
RUN cat ${scriptsDir}bashrc-update.txt >> /etc/bash.bashrc
RUN cat ${scriptsDir}bashrc-update.txt >> /home/zowe/.bashrc
RUN rm ${scriptsDir}bashrc-update.txt

# Install zowe
RUN su -c "install_zowe.sh true" - zowe 

# Cleanup
RUN apt-get -q autoremove && apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin
RUN rm -rdf ${tempDir}

# Standard SSH port
EXPOSE 22

# Execute the setup script when the image is run. Setup will install the desired version via 
# nvm for both the root user and zowe - then start the ssh service
ENTRYPOINT ["docker-entrypoint.sh"]

# Default command
CMD ["/usr/sbin/sshd", "-D"]
