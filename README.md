The Dockerfile in this directory sets up an Ubuntu Trusty image ready to build
a variety of Android branches (>= Lollipop). It's particulary useful to build
older branches that required 14.04 if you've upgraded to something newer.

First, build the image:
```
# Copy your host gitconfig. This will overwrite --build-arg git_* arguments
$ cp ~/.gitconfig ./configs/.gitconfig

# Copy your SSH config. This will owervite --build-arg ssh_* arguments
$ cp ~/.ssh/* ./.ssh/

# Build docker image
$ docker build \
--build-arg userid=$(id -u) \
--build-arg groupid=$(id -g) \
--build-arg username=$(id -un) \
--build-arg password=\'$(mkpasswd  -m sha-512 -S saltsalt -s <<< password)\' \
--build-arg git_user_mail="developer@mail.com" \
--build-arg git_user_name="Developer Name" \
--build-arg ssh_prv_key="$(cat ~/.ssh/id_rsa)" \
--build-arg ssh_pub_key="$(cat ~/.ssh/id_rsa.pub)" \
--build-arg ssh_known_hosts="$(ssh-keyscan -H github.com)" \
--build-arg ssh_config="$(cat ~/.ssh/config)" \
-t android-build-trusty .
```

Create a folde to share data between host OS and Docker container. 
Set ANDROID_BUILD_TOP variable a FULL path to the folder which will be shared between host OS and Docker container.
All AOSP sources will be downloaded, stored and built in that folder.

$ export ANDROID_BUILD_TOP=<full_path_to_the_shared_folder>


Then you can start up new instances with:
```
$ docker run -it --rm -v $ANDROID_BUILD_TOP:/src android-build-trusty

After conteiner has started you will be switched to the continer console.
To download and build android-6.0.0_r1 AOSP for x86_64 platform run next commands:

> cd /src;
> repo init -u https://android.googlesource.com/platform/manifest -b android-6.0.0_r1
> repo sync -j8
> source build/envsetup.sh
> lunch aosp_x86_64-eng
> m -j8
```

After the build has completed exit container. 
The build AOSP can be found in folder, specified in ANDROID_BUILD_TOP variable.
