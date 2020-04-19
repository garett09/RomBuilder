#!/bin/bash

# Script for local build V1.0

error_exit()
{
    ret="$?"
    if [ "$ret" != "0" ]; then
        echo "Error - '$1' failed with return code '$ret'"
        exit 1
    fi
}

# Install requirements for build
CURRENT="$(pwd)"

# Requirements for buildkite

if [ -f "/etc/lsb-release" ] && [ ! -d "/opt/build_env" ]; then
  # Linux install
  echo "Pulling and installing tools"
  git clone https://github.com/akhilnarang/scripts.git /opt/build_env --depth=1
  sudo chmod +x /opt/build_env/setup/android_build_env.sh
  . /opt/build_env/setup/android_build_env.sh

  apt-get -y upgrade > /dev/null 2>&1 && \
  apt-get -y install make python3 bc bison git screen wget openjdk-8-jdk python-lunch lsb-core sudo curl shellcheck \
  autoconf libtool g++ libcrypto++-dev build-essential libz-dev libsqlite3-dev libssl-dev libcurl4-gnutls-dev libreadline-dev \
  libpcre++-dev libsodium-dev libc-ares-dev libfreeimage-dev libavcodec-dev libavutil-dev libavformat-dev flex \
  libswscale-dev libmediainfo-dev libzen-dev libuv1-dev libxkbcommon-dev libxkbcommon-x11-0 zram-config \
  libelf-dev libncurses-dev g++-multilib gcc-multilib gperf libxml2 libxml2-utils zlib1g-dev zip yasm \
  squashfs-tools xsltproc schedtool rsync lzop liblz4-tool libesd0-dev lib32z1-dev lib32readline-dev libsdl1.2-dev > /dev/null 2>&1   

  # Download and build mega
  if [ ! -d "/opt/MEGAcmd/" ]; then
    wget --quiet -O /opt/megasync.deb https://mega.nz/linux/MEGAsync/xUbuntu_$(lsb_release -rs)/amd64/megasync-xUbuntu_$(lsb_release -rs)_amd64.deb && ls /opt/ && dpkg -i /opt/megasync.deb
    cd /opt/ && git clone --quiet https://github.com/meganz/MEGAcmd.git
    cd /opt/MEGAcmd && git submodule update --quiet --init --recursive && sh autogen.sh > /dev/null 2>&1 && ./configure --quiet && make > /dev/null 2>&1 && make install > /dev/null 2>&1
  fi

  apt update --fix-missing
  sudo apt install -f

else
  # MacOS install - todo
  echo ""
fi

# Sets vars for run script
export OUTPUT_DIR=$(pwd)/../files/;
if [[ -z "${BUILDKITE}" ]]; then
  mkdir "$OUTPUT_DIR" > /dev/null 2>&1
fi

if [[ -z "${BUILDKITE}" ]]; then
  export BUILD_NAME=aosp
  export UPLOAD_NAME=evox
  export MEGA_USERNAME=robbalmbra@gmail.com
  export MEGA_PASSWORD=Er1hcK0wN$PIhN4mT$K#U@5ZusH0zdcT
  export DEVICES=crownlte,starlte,star2lte
  export REPO=https://github.com/Evolution-X/manifest
  export USE_CCACHE=1
  export CUSTOM_BUILD_TYPE=UNOFFICIAL
  export TARGET_BOOT_ANIMATION_RES=1080
  export TARGET_GAPPS_ARCH=arm64
  export TARGET_SUPPORTS_GOOGLE_RECORDER=true
  export DEVICE_MAINTAINERS="Tiny Rob, Blast"
  export CCACHE_DIR=$OUTPUT_DIR/ccache
  export BRANCH=ten
  export BOOT_LOGGING=1
  export LOCAL_REPO=https://github.com/robbalmbra/local_manifests.git
  export LOCAL_BRANCH=android-10.0
  
  # User modifications
  export USER_MODIFICATIONS=""
fi

# Check vars
variables=(
  CCACHE_DIR
  BUILD_NAME
  UPLOAD_NAME
  MEGA_USERNAME
  MEGA_PASSWORD
  DEVICES
  REPO
  BRANCH
  LOCAL_REPO
  LOCAL_BRANCH
)

# Check if required variables are set
quit=0
for variable in "${variables[@]}"
do
  if [[ -z ${!variable+x} ]]; then
    echo "$0 - Error, $variable isn't set.";
    exit 1
  fi
done

# Check and get user modifications either as a url or env string
cd "$CURRENT"
if [[ ! -z "$USER_MODIFICATIONS" ]]; then
  regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
  if [[ $USER_MODIFICATIONS =~ $regex ]]
  then 
    # Get url and save to local file
    echo "Downloading and saving USER_MODIFICATIONS to '$CURRENT/user_modifications.sh'"
    wget $USER_MODIFICATIONS -O "$CURRENT/user_modifications.sh"
  else
    echo "Saving USER_MODIFICATIONS to '$CURRENT/user_modifications.sh'"
    echo $USER_MODIFICATIONS > "$CURRENT/user_modifications.sh"
  fi
fi

# Run build
echo "Running build script"
chmod +x "$CURRENT/user_modifications.sh"
chmod +x "$CURRENT/buildkite_logger.sh"
export USER_MODS="$CURRENT/user_modifications.sh"
export BUILDKITE_LOGGER="$CURRENT/buildkite_logger.sh"
"$(pwd)/../docker/build.sh"
error_exit "build script"
