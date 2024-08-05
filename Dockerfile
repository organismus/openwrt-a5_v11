FROM debian:bullseye-slim AS builder

RUN apt-get update &&\
    apt-get install -y \
        sudo time git-core subversion build-essential g++ bash make \
        libssl-dev patch libncurses5 libncurses5-dev zlib1g-dev gawk \
        flex gettext wget unzip xz-utils python \
        python3 python3-distutils-extra rsync curl libsnmp-dev liblzma-dev \
        libpam0g-dev cpio rsync gcc-multilib g++-multilib file libelf-dev fastjar \
	mini-httpd vim zstd lynx && \
    apt-get clean && \
    useradd -m user && \
    echo 'user ALL=NOPASSWD: ALL' > /etc/sudoers.d/user

WORKDIR /home/user
USER user
RUN ls -la
COPY .config* ./
COPY a5-v11_*.patch ./
COPY openwrt.sh ./
COPY feeds.conf.default ./

# set dummy git config
RUN git config --global user.name "user" && git config --global user.email "user@example.com"

ARG V
ENV V=$V

RUN     ./openwrt.sh fetch configure patch make

FROM scratch
COPY --from=builder /home/user/openwrt/bin/targets/ramips/rt305x/*.bin ./
