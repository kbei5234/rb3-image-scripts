#!/bin/bash -x

BASEDIR=$(realpath $(dirname $0))
NAME=working
TARGET=${BASEDIR}/${NAME}
#MANIFEST=qcom-6.6.28-QLI.1.1-Ver.1.1.xml
MANIFEST=qcom-6.6.28-QLI.1.1-Ver.1.1_qim-product-sdk-1.1.3.xml
QIM_RELEASE=qcom-6.6.28-QLI.1.1-Ver.1.1_qim-product-sdk-1.1.3
LINUX_RELEASE=qcom-6.6.28-QLI.1.1-Ver.1.1_realtime-linux-1.0
USERNAME=karen.bei@tufts.edu

# install qsc cli
sudo apt install curl
cd $BASEDIR
curl -L https://softwarecenter.qualcomm.com/api/download/software/qsc/linux/latest.deb -o qsc_installer.deb
sudo dpkg -i qsc_installer.deb
qsc-cli login -u $USERNAME

# ----------------- build with standalone commands -----------------
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

# add qualcomm id with personalized access token
qsc-cli login -u $USERNAME
# Run the following command to generate PAT
export PAT_TOKEN=$(qsc-cli pat --get)
echo $PAT_TOKEN
# add the following entries
cat >> ~/.netrc << EOL
#cat >> /home/turbox/workspace/.sdkmanager.config/.netrc << EOL
machine chipmaster2.qti.qualcomm.com
login $USERNAME
password $PAT_TOKEN
machine qpm-git.qualcomm.com
login $USERNAME
password $PAT_TOKEN
EOL

# set up locales
sudo locale-gen en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# update git configs
git config --get user.email
git config --get user.name
git config --global color.ui auto
# fetch large size repos
git config --global http.postBuffer 1048576000
git config --global http.maxRequestBuffer 1048576000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999
# follow remote redirects
git config --global http.https://chipmaster2.qti.qualcomm.com.followRedirects true
git config --global http.https://qpm-git.qualcomm.com.followRedirects true

# download qualcomm yocto and supporting layers
mkdir $TARGET
cd $TARGET
repo --time init -u https://github.com/quic-yocto/qcom-manifest -b qcom-linux-kirkstone -m $MANIFEST
repo sync

# clone qimp sdk layer
git clone https://github.com/quic-yocto/meta-qcom-qim-product-sdk -b $QIM_RELEASE layers/meta-qcom-qim-product-sdk
export EXTRALAYERS="meta-qcom-qim-product-sdk"

# setup build environment and enter build-qcom-wayland directory
MACHINE=qcm6490 DISTRO=qcom-wayland source setup-environment

start_time=$(date -u +%s)

# build images
bitbake qcom-multimedia-image
bitbake qim-product-sdk

cd $TARGET/build-qcom-wayland/tmp-glibc/deploy/images/qcm6490/qcom-multimedia-image
ls -al system.img

# clone qimp sdk layer 
#cd $TARGET
#git clone https://github.com/quic-yocto/meta-qcom-qim-product-sdk -b $QIM_RELEASE layers/meta-qcom-qim-product-sdk
#export EXTRALAYERS="meta-qcom-qim-product-sdk"

# setup build environment and build image
#MACHINE=qcm6490 DISTRO=qcom-wayland source setup-environment
#bitbake qim-product-sdk

# download qirp sdk layers
#cd $TARGET
#git clone https://git.codelinaro.org/clo/le/meta-ros.git -b ros.qclinux.1.0.r1-rel layers/meta-ros
#git clone https://github.com/quic-yocto/meta-qcom-robotics.git layers/meta-qcom-robotics
#git clone https://github.com/quic-yocto/meta-qcom-robotics-distro.git layers/meta-qcom-robotics-distro
#git clone https://github.com/quic-yocto/meta-qcom-robotics-sdk.git layers/meta-qcom-robotics-sdk
#git clone https://github.com/quic-yocto/meta-qcom-qim-product-sdk layers/meta-qcom-qim-product-sdk

# setup build environment
#ln -s layers/meta-qcom-robotics-distro/set_bb_env.sh ./setup-robotics-environment
#ln -s layers/meta-qcom-robotics-sdk/scripts/qirp-build ./qirp-build
#MACHINE=qcm6490 DISTRO=qcom-robotics-ros2-humble source setup-robotics-environment

# build robotics image
#../qirp-build qcom-robotics-full-image

# download linux layers
#cd $TARGET
#git clone https://github.com/quic-yocto/meta-qcom-realtime -b $LINUX_RELEASE layers/meta-qcom-realtime
#export EXTRALAYERS="meta-qcom-realtime"
#MACHINE=qcm6490 DISTRO=qcom-wayland source setup-environment
#bitbake qcom-multimedia-image

end_time=$(date -u +%s)
echo ====
echo Build consumed: $((($end_time - $start_time) / 60)) min
