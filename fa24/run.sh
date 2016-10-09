#!/bin/bash

set -xe

dnf install -y \
@development-tools \
createrepo \
kpartx \
git \
python-backports-lzma \
python-devel \
python-pip \
python-yaml \
sudo \
rpm-build \
rpm-ostree-toolbox \
@virtualization \
yum \
yum-utils

cd /root
git clone https://pagure.io/fedora-atomic.git
cd fedora-atomic
git checkout f24


#sed -i 's/\"atomic\",/"atomic",\ \"os-apply-config\",\ \"os-collect-config\",\ \"os-refresh-config\",/' fedora-atomic-docker-host.json

cd /root

mkdir -p /srv/f24ah
ostree init --repo=/srv/f24ah --mode=archive-z2
rpm-ostree compose tree --repo=/srv/f24ah /root/fedora-atomic/fedora-atomic-docker-host.json

ostree trivial-httpd -d -P 9001 /srv/f24ah

cd /root



git clone https://git.openstack.org/openstack/magnum
git clone https://git.openstack.org/openstack/diskimage-builder.git
git clone https://git.openstack.org/openstack/dib-utils.git

export PATH="${PWD}/dib-utils/bin:$PATH"
export PATH="${PWD}/diskimage-builder/bin:$PATH"

export ELEMENTS_PATH="${PWD}/diskimage-builder/elements"
export ELEMENTS_PATH="${ELEMENTS_PATH}:${PWD}/magnum/magnum/drivers/common/image"

export DIB_RELEASE=24
export DIB_DEBUG_TRACE=1
export DIB_IMAGE_SIZE=3.0

export FEDORA_ATOMIC_TREE_URL=http://localhost:9001
export FEDORA_ATOMIC_TREE_REF=$(cat /srv/f24ah/refs/heads/fedora-atomic/24/x86_64/docker-host)

mkdir -p /output

disk-image-create fedora-atomic -o /output/fedora-atomic

