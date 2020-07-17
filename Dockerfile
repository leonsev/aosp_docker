FROM ubuntu:14.04
ARG userid=1001
ARG groupid=1001
ARG username=developer
# Default password is 'password'
ARG password='$6$ldfK792N$E0jeNC3MhpDfhXo9V.tDJ2Qt84Qx3lbZtdOLD.SNDcX5kJQT1pNibj3npqeevRgbA5ARDeND5uTWwBDpdZ66T.'
ARG ssh_prv_key=""
ARG ssh_pub_key=""

RUN apt-get update && apt-get install -y bc git-core gnupg flex bison gperf build-essential zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev ccache libgl1-mesa-dev libxml2-utils xsltproc unzip python openjdk-7-jdk

# To build Android 6.0 (Marshmallow) we require JDK 7 according to
# https://source.android.com/setup/build/older-versions
#RUN curl -o jdk8.tgz https://android.googlesource.com/platform/prebuilts/jdk/jdk8/+archive/master.tar.gz \
# && tar -zxf jdk8.tgz linux-x86 \
# && mv linux-x86 /usr/lib/jvm/java-8-openjdk-amd64 \
# && rm -rf jdk8.tgz

RUN apt-get install openjdk-7-jre

RUN curl -o /usr/local/bin/repo https://storage.googleapis.com/git-repo-downloads/repo \
 && echo "d73f3885d717c1dc89eba0563433cec787486a0089b9b04b4e8c56e7c07c7610  /usr/local/bin/repo" | sha256sum --strict -c - \
 && chmod a+x /usr/local/bin/repo

RUN groupadd -g $groupid $username \
 && useradd -m -u $userid -g $groupid -G sudo -p ${password} $username \
 && echo $username >/root/username \
 && echo "export USER="$username >>/home/$username/.gitconfig
COPY gitconfig /home/$username/.gitconfig
RUN chown $userid:$groupid /home/$username/.gitconfig
RUN mkdir -p /home/$username/.ssh
# Add known hosts
RUN ssh-keyscan -H bitbucket.org >> /home/$username/.ssh/known_hosts
RUN ssh-keyscan -H github.com >> /home/$username/.ssh/known_hosts
COPY known_hosts /home/$username/.ssh/known_hosts
RUN chown $userid:$groupid /home/$username/.ssh/known_hosts
ENV HOME=/home/$username
ENV USER=$username

# Add the keys and set permissions
RUN echo "$ssh_prv_key" > /home/$username/.ssh/id_rsa && \
    echo "$ssh_pub_key" > /home/$username/.ssh/id_rsa.pub && \
    chmod 600 /home/$username/.ssh/id_rsa && \
    chmod 600 /home/$username/.ssh/id_rsa.pub && \
    chown $username:$username /home/$username/.ssh/id_rsa && \
    chown $username:$username /home/$username/.ssh/id_rsa.pub

ENTRYPOINT chroot --userspec=$(cat /root/username):$(cat /root/username) / /bin/bash -i
