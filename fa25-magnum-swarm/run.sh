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
git checkout f25

git apply 0001-magnum-Add-flannel-and-etcd.patch

cd /root

mkdir -p /srv/f25ah
ostree init --repo=/srv/f25ah --mode=archive-z2
rpm-ostree compose tree --repo=/srv/f25ah /root/fedora-atomic/fedora-atomic-docker-host.json

ostree trivial-httpd -d -P 9001 /srv/f25ah

cd /root



git clone https://git.openstack.org/openstack/magnum
git clone https://git.openstack.org/openstack/diskimage-builder.git
git clone https://git.openstack.org/openstack/dib-utils.git

export PATH="${PWD}/dib-utils/bin:$PATH"
export PATH="${PWD}/diskimage-builder/bin:$PATH"

export ELEMENTS_PATH="${PWD}/diskimage-builder/elements"
export ELEMENTS_PATH="${ELEMENTS_PATH}:${PWD}/magnum/magnum/drivers/common/image"

export DIB_RELEASE=25
export DIB_DEBUG_TRACE=1
export DIB_IMAGE_SIZE=3.0

export FEDORA_ATOMIC_TREE_URL=http://localhost:9001
export FEDORA_ATOMIC_TREE_REF=$(cat /srv/f25ah/refs/heads/fedora-atomic/25/x86_64/docker-host)

mkdir -p /output

disk-image-create fedora-atomic -o /output/fedora-atomic

