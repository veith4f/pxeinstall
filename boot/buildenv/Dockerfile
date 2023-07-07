FROM debian:12

# install deps
RUN apt-get update && apt-get install -y \
    uuid-runtime \
    dosfstools \
    lvm2 \
    parted \
    efibootmgr \
    sbsigntool \
    cloud-guest-utils \
    gnupg \
    linux-image-amd64 \
    openssl \
    make \
    binutils \
    bison \
    gcc \
    gettext \
    flex \
    curl \
    bison

# get and build grub-2.06
RUN cd /root && \
	curl -O ftp.gnu.org/gnu/grub/grub-2.06.tar.gz && \
	tar -xvzf grub-2.06.tar.gz && \
	cd grub-2.06 && \
	./configure --prefix=/usr/local --with-platform=efi && \
	find . -name Makefile -exec sed -i 's/-Werror/-Wno-error/g' {} \; && \
	make && \
	make install

# prepare grub image, kernel and ramdisk
CMD /root/scripts/mkstandalone.sh
