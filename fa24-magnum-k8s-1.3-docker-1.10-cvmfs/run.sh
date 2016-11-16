#!/bin/bash

set -xe

# install deps for fedora
../install-deps.sh

# Download kubernetes 1.3 packages
cd /root
rm -rf /srv/mykuberepo
mkdir -p /srv/mykuberepo
cd /srv/mykuberepo
KUBE_RPMS_DIR_URL="https://kojipkgs.fedoraproject.org/packages/kubernetes/1.3.0/0.2.git507d3a7.fc25/x86_64/"

for PKG in $(curl -s $KUBE_RPMS_DIR_URL | grep -o ">kube.*\.rpm" | sed 's/>//') ; do 
  curl -sSo "$PKG $KUBE_RPMS_DIR_URL$PKG" ;
done

createrepo /srv/mykuberepo

# create cvmfs-ostree-integration package
cd /root
rm -rf /root/cvmfs-ostree-integration
rm -rf /root/rpmbuild/
cd /root
git clone https://gitlab.cern.ch/strigazi/cvmfs-ostree-integration.git
cd cvmfs-ostree-integration
mkdir -p /root/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
cp ./* /root/rpmbuild/SOURCES
rpmbuild -bb cvmfs-mount-point.spec
rm -rf /srv/local-repo
mkdir /srv/local-repo
mv /root/rpmbuild/RPMS/x86_64/cvmfs-mount-point-* /srv/local-repo
createrepo /srv/local-repo/

cd /root
git clone https://github.com/strigazi/fedora-atomic.git -b fa24-k8s-1.3-docker-1.10.3-cvmfs

cd /root

rm -rf /srv/f24ah
mkdir -p /srv/f24ah
ostree init --repo=/srv/f24ah --mode=archive-z2
rpm-ostree compose tree --repo=/srv/f24ah /root/fedora-atomic/fedora-atomic-docker-host.json

kill -15 $(ps aux | grep trivial | grep ostree | awk '{print $2}')
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
export FEDORA_ATOMIC_TREE_REF
FEDORA_ATOMIC_TREE_REF=$(cat /srv/f24ah/refs/heads/fedora-atomic/24/x86_64/docker-host)

rm -rf /output/*
mkdir -p /output

disk-image-create fedora-atomic -o /output/fedora-atomic-24-k8s-1.3-docker-1.10.3-cvmfs

