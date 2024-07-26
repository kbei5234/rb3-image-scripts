#!/bin/bash -x

BASEDIR=$(realpath $(dirname $0))
NAME=working
TARGET=${BASEDIR}/${NAME}
MANIFEST=qcom-6.6.28-QLI.1.1-Ver.1.1_robotics-product-sdk-1.1.xml

# install packages
sudo apt update
sudo apt install gawk wget git diffstat unzip texinfo gcc build-essential chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint xterm python3-subunit mesa-common-dev zstd liblz4-tool locales tar python-is-python3 file libxml-opml-simplegen-perl vim whiptail

# install repo
rm -rf ~/bin/repo_tool
mkdir -p ~/bin
cd ~/bin
git clone https://android.googlesource.com/tools/repo.git -b v2.41 repo_tool
cd repo_tool
git checkout -b v2.41
export PATH=~/bin/repo_tool:$PATH

# set up locales
sudo locale-gen en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# update git configurations
git config --get user.email
git config --get user.name
#if not configured, then run below two lines
#git config --global user.email <Your email ID>
#git config --global user.name <"Your Name">
git config --global color.ui auto
git config --global http.postBuffer 1048576000
git config --global http.maxRequestBuffer 1048576000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999

# download QUALCOMM yocto and supporting layers
mkdir $TARGET
cd $TARGET 
repo --time init -u https://github.com/quic-yocto/qcom-manifest -b qcom-linux-kirkstone -m $MANIFEST
repo sync 

# download qirp sdk into base build
git clone https://git.codelinaro.org/clo/le/meta-ros.git -b ros.qclinux.1.0.r1-rel layers/meta-ros
git clone https://github.com/quic-yocto/meta-qcom-robotics.git layers/meta-qcom-robotics
git clone https://github.com/quic-yocto/meta-qcom-robotics-distro.git layers/meta-qcom-robotics-distro
git clone https://github.com/quic-yocto/meta-qcom-robotics-sdk.git layers/meta-qcom-robotics-sdk
git clone https://github.com/quic-yocto/meta-qcom-qim-product-sdk layers/meta-qcom-qim-product-sdk

start_time=$(date -u +%s)

# setup build environment for qirp
ln -s layers/meta-qcom-robotics-distro/set_bb_env.sh ./setup-robotics-environment
ln -s layers/meta-qcom-robotics-sdk/scripts/qirp-build ./qirp-build
MACHINE=qcm6490 DISTRO=qcom-robotics-ros2-humble source setup-robotics-environment

# build qirp image and sdk artifacts
../qirp-build qcom-robotics-full-image
# to see qirp sdk tar file
ls -l $TARGET/build-qcom-robotics-ros2-humble/tmp-glibc/deploy/qirpsdk_artifacts
# to see full image
ls -l $TARGET/build-qcom-robotics-ros2-humble/tmp-glibc/deploy/images/qcm6490

end_time=$(date -u +%s)
echo ====
echo Build consumed: $((($end_time - $start_time) / 60)) min
