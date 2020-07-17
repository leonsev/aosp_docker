FROM ubuntu:14.04

RUN apt-get update && apt-get install -y software-properties-common
# Added repository for python 3.6
RUN add-apt-repository ppa:deadsnakes/ppa
# Added repository for latest git
RUN add-apt-repository ppa:git-core/ppa

# Install Recommended by Google packages
RUN apt-get update && apt-get install -y git-core gnupg flex bison gperf build-essential \
    zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 lib32ncurses5-dev x11proto-core-dev \
    libx11-dev lib32z-dev ccache libgl1-mesa-dev libxml2-utils xsltproc unzip python openjdk-7-jdk

# Install all the Linux packages required for comfortable development work. Note that the packages python3,
# tar, locales and cpio are not listed in the official documentation.
RUN  apt-get -y install apt-utils gawk wget diffstat texinfo \
     chrpath socat cpio python3.6 xz-utils debianutils iputils-ping libsdl1.2-dev \
     xterm minicom tar locales sudo mc rsync bc

# To build Android 6.0 (Marshmallow) we require JDK 7 according to
# https://source.android.com/setup/build/older-versions
# RUN curl -o jdk8.tgz https://android.googlesource.com/platform/prebuilts/jdk/jdk8/+archive/master.tar.gz \
# && tar -zxf jdk8.tgz linux-x86 \
# && mv linux-x86 /usr/lib/jvm/java-8-openjdk-amd64 \
# && rm -rf jdk8.tgz

RUN curl -o /usr/local/bin/repo https://storage.googleapis.com/git-repo-downloads/repo \
 && echo "d73f3885d717c1dc89eba0563433cec787486a0089b9b04b4e8c56e7c07c7610  /usr/local/bin/repo" | sha256sum --strict -c - \
 && chmod a+x /usr/local/bin/repo

# Use this ARGs to configure user
ARG userid=1001
ARG groupid=1001
ARG username=developer
# Default password is 'password'
ARG password='$6$ldfK792N$E0jeNC3MhpDfhXo9V.tDJ2Qt84Qx3lbZtdOLD.SNDcX5kJQT1pNibj3npqeevRgbA5ARDeND5uTWwBDpdZ66T.'

# Use this ARGs to configure git
ARG git_user_mail=${username}@mail.com
ARG git_user_name=${username}

# Use this ARGs to inject own ssh configuration to the image
ARG ssh_prv_key=""
ARG ssh_pub_key=""
ARG ssh_known_hosts=""
ARG ssh_config=""

RUN groupadd -g $groupid $username \
 && useradd -m -u $userid -g $groupid -G sudo -p ${password} $username \
 && echo $username >/root/username
ENV HOME=/home/$username
ENV USER=$username

# Now all comands are executed from user
USER $username

# Configure SSH
RUN mkdir -p /home/$username/.ssh && \
    echo "$ssh_prv_key" > /home/$username/.ssh/id_rsa && \
    echo "$ssh_pub_key" > /home/$username/.ssh/id_rsa.pub && \
    echo "$ssh_known_hosts" > /home/$username/.ssh/known_hosts && \
    echo "$ssh_config" > /home/$username/.ssh/config
# Add known hosts, as example
RUN ssh-keyscan -H bitbucket.org >> /home/$username/.ssh/known_hosts
RUN ssh-keyscan -H github.com >> /home/$username/.ssh/known_hosts
# Other way to owervrite full SSH config is to put all required files to the local ./.ssh folder
COPY ./.ssh/* /home/$username/.ssh/

# Configure git
RUN git config --global user.email $git_user_mail
RUN git config --global user.name $git_user_name
RUN git config --global color.ui always
RUN git config --global color.branch always
RUN git config --global color.status always
# This overrides previous gitconfig settings, if .gitconfig exists
COPY ./configs/* /home/$username/

USER root
ENTRYPOINT chroot --userspec=$(cat /root/username):$(cat /root/username) / /bin/bash -i