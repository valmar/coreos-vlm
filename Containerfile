FROM quay.io/fedora/fedora-coreos:stable as kernel-query
RUN rpm -qa kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' > /kernel-version.txt
FROM registry.fedoraproject.org/fedora:39 as builder
COPY --from=kernel-query /kernel-version.txt /kernel-version.txt
WORKDIR /etc/yum.repos.d
RUN curl -L -O https://src.fedoraproject.org/rpms/fedora-repos/raw/f39/f/fedora-updates-archive.repo && \
    sed -i 's/enabled=AUTO_VALUE/enabled=true/' fedora-updates-archive.repo
RUN dnf install -y jq dkms gcc make autoconf automake libtool rpm-build libtirpc-devel libblkid-devel \
    libuuid-devel libudev-devel openssl-devel zlib-devel libaio-devel libattr-devel elfutils-libelf-devel \
    kernel-$(cat /kernel-version.txt) kernel-modules-$(cat /kernel-version.txt) kernel-devel-$(cat /kernel-version.txt) \
    python3 python3-devel python3-setuptools python3-cffi libffi-devel git ncompress libcurl-devel
WORKDIR /
RUN curl "https://release-monitoring.org/api/v2/versions/?project_id=11706" | jq --raw-output '.stable_versions[0]' >> /zfs_version.txt
RUN curl -L -O https://github.com/openzfs/zfs/releases/download/zfs-$(cat /zfs_version.txt)/zfs-$(cat /zfs_version.txt).tar.gz && \
    tar xzf zfs-$(cat /zfs_version.txt).tar.gz && mv zfs-$(cat /zfs_version.txt) zfs
WORKDIR /zfs
RUN ./configure -with-linux=/usr/src/kernels/$(cat /kernel-version.txt)/ -with-linux-obj=/usr/src/kernels/$(cat /kernel-version.txt)/ \
    && make -j1 rpm-utils rpm-kmod

FROM quay.io/fedora/fedora-coreos:stable
COPY --from=builder /zfs/*.rpm /zfs/
COPY usr /usr
RUN rm /zfs/*devel*.rpm /zfs/zfs-test*.rpm && \
    rpm-ostree install \
      /zfs/*.$(rpm -qa kernel --queryformat '%{ARCH}').rpm && \
    depmod -a "$(rpm -qa kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')" && \
    echo "zfs" > /etc/modules-load.d/zfs.conf && \
    rm -rf /var/lib/pcp && \
    cd /etc/yum.repos.d/ && \
    curl -LO https://pkgs.tailscale.com/stable/fedora/tailscale.repo && \
    rpm-ostree override replace libgomp libgcc --experimental --from repo='fedora' && \
    rpm-ostree install diffstat \
                       doxygen \
                       firewalld \
		       git \
		       patch \
		       patchutils \
		       systemtap \
                       tailscale \
                       tuned \
                       tuned-profiles-atomic \
                       tuned-utils && \
    systemctl enable tailscaled && \
    systemctl enable tuned && \
    systemctl enable firewalld && \
    systemctl enable rpm-ostreed-automatic.timer && \
    ostree container commit 
