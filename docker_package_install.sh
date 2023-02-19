#!/bin/sh

echo "[*] Installing packages"
STEP=$1
if [ -z "$STEP" ]; then
    echo "[!] Must specify 'builder' or 'stage2' as arguments"
    exit 1
elif [ "$STEP" = 'builder' ]; then
    echo "[*] Builder step"
elif [ "$STEP" = 'stage2' ]; then
    echo "[*] Stage2 step"
fi

# Load OS info
# shellcheck source=/dev/null
. /etc/os-release

if [ "${ID}" = 'debian' ] || [ "${ID_LIKE}" = 'debian' ]; then
    [ "${ID_LIKE}" = 'debian' ] && echo "[*] Detected debian-based distro: ${ID} (${VERSION_ID})"
    [ "${ID}" = 'debian' ] && echo "[*] Detected debian (${VERSION_CODENAME}/${VERSION_ID})"
    if [ "${STEP}" = 'builder' ]; then
        apt-get update \
        && export DEBIAN_FRONTEND=noninteractive \
        && apt-get -y install --no-install-recommends \
            build-essential autoconf automake libtool pkg-config libnl-3-dev libnl-genl-3-dev libssl-dev \
            ethtool shtool rfkill zlib1g-dev libpcap-dev libsqlite3-dev libpcre2-dev libhwloc-dev \
            libcmocka-dev hostapd wpasupplicant tcpdump screen iw usbutils expect gawk bear \
            libtinfo5 python3-pip git && \
                rm -rf /var/lib/apt/lists/*
    elif [ "${STEP}" = 'stage2' ]; then
        apt-get update && \
        apt-get -y install --no-install-recommends \
            libsqlite3-0 libssl3 hwloc libpcre2-posix3 libnl-3-200 libnl-genl-3-200 iw usbutils pciutils \
            iproute2 ethtool kmod wget ieee-data python3 python3-graphviz rfkill && \
        rm -rf /var/lib/apt/lists/*
    fi
elif [ "${ID}" = 'arch' ] || [ "${ID_LIKE}" = 'arch' ]; then
    [ "${ID}" = 'arch' ] && echo "[*] Detected Arch Linux"
    [ "${ID_LIKE}" = 'arch' ] && echo "[*] Detected Arch-based Linux: ${NAME} (${ID})"
    if [ "${STEP}" = 'builder' ]; then
        pacman -Sy --noconfirm base-devel libnl openssl ethtool util-linux zlib libpcap sqlite pcre2 hwloc \
                                cmocka hostapd wpa_supplicant tcpdump screen iw usbutils pciutils expect git \
                                python python-setuptools
    elif [ "${STEP}" = 'stage2' ]; then
        pacman -Sy --noconfirm libnl openssl ethtool util-linux zlib libpcap sqlite pcre2 hwloc iw usbutils \
                                pciutils python-graphviz python
    fi
elif [ "${ID}" = 'alpine' ]; then
    echo "[*] Detected alpine"
    if [ "${STEP}" = 'builder' ]; then
        apk add --no-cache \
            gcc g++ make autoconf automake libtool libnl3-dev openssl-dev ethtool libpcap-dev cmocka-dev \
            hostapd wpa_supplicant tcpdump screen iw pkgconf util-linux sqlite-dev pcre2-dev linux-headers \
            zlib-dev pciutils usbutils expect hwloc-dev git python3 expect gawk bear py3-pip
    elif [ "${STEP}" = 'stage2' ]; then
        apk add --no-cache \
            libnl3 openssl ethtool libpcap util-linux sqlite-dev pcre2 zlib pciutils usbutils hwloc wget \
            iproute2 kmod python3 py3-graphviz urfkill iw 
    fi
elif [ "${ID}" = 'fedora' ] || [ "${ID}" = 'almalinux' ] || [ "${ID}" = 'rocky' ]; then
    echo "[*] Distribution: ${NAME} (${VERSION_ID})"
    if [ "${STEP}" = 'builder' ]; then
        if [ "${ID}" = 'almalinux' ] || [ "${ID}" = 'rocky' ]; then
            echo "[*] Install EPEL and enabling CRB"
            dnf install epel-release dnf-plugins-core -y
            dnf config-manager --set-enabled crb
        fi

        dnf install -y libtool pkgconfig sqlite-devel autoconf automake openssl-devel libpcap-devel \
                        pcre2-devel rfkill libnl3-devel gcc gcc-c++ ethtool hwloc-devel libcmocka-devel \
                        make file expect hostapd wpa_supplicant iw usbutils tcpdump screen zlib-devel \
                        expect python3-pip python3-setuptools git
    elif [ "${STEP}" = 'stage2' ]; then
        GRAPHVIZ=python3-graphviz
        [ "${ID}" != 'fedora' ] && GRAPHVIZ=graphviz-python3
        dnf install -y libnl3 openssl-libs zlib libpcap sqlite-libs pcre2 hwloc iw ethtool pciutils \
                        usbutils expect python3 ${GRAPHVIZ} iw util-linux ethtool kmod
    fi
elif [ "${ID}" = 'opensuse-leap' ]; then
    echo "[*] Detected openSUSE Leap"
    if [ "${STEP}" = 'builder' ]; then
        zypper install -y autoconf automake libtool pkg-config libnl3-devel libopenssl-1_1-devel zlib-devel \
                        libpcap-devel sqlite3-devel pcre2-devel hwloc-devel libcmocka-devel hostapd screen \
                        wpa_supplicant tcpdump iw gcc-c++ gcc ethtool pciutils usbutils expect python3-pip \
                        python3-setuptools git
    elif [ "${STEP}" = 'stage2' ]; then
        zypper install -y libnl3-200 libopenssl1_1 zlib libpcap sqlite3 libpcre2-8-0 hwloc iw ethtool pciutils \
                        usbutils expect python3 python3-graphviz iw util-linux ethtool kmod
    fi
elif [ "${ID}" = 'gentoo' ]; then
    echo "[*] Detected Gentoo"
    if [ "${STEP}" = 'builder' ]; then
        export EMERGE_DEFAULT_OPTS="--binpkg-respect-use=y --getbinpkg=y"
        cat <<EOF >/etc/portage/binrepos.conf
[binhost]
priority = 9999
sync-uri = https://gentoo.osuosl.org/experimental/amd64/binpkg/default/linux/17.1/x86-64/
EOF
        emerge --sync
        emerge app-portage/elt-patches dev-db/sqlite dev-lang/python dev-libs/libbsd dev-libs/libnl dev-libs/libpcre \
                dev-libs/openssl dev-vcs/git net-libs/libpcap net-wireless/iw net-wireless/lorcon sys-apps/hwloc \
                net-wireless/wireless-tools sys-apps/ethtool sys-apps/hwdata sys-apps/pciutils sys-apps/usbutils \
                sys-devel/autoconf sys-devel/automake sys-devel/gnuconfig sys-devel/libtool sys-libs/zlib
    elif [ "${STEP}" = 'stage2' ]; then
        export EMERGE_DEFAULT_OPTS="--binpkg-respect-use=y --getbinpkg=y"
        cat <<EOF >/etc/portage/binrepos.conf
[binhost]
priority = 9999
sync-uri = https://gentoo.osuosl.org/experimental/amd64/binpkg/default/linux/17.1/x86-64/
EOF
        emerge --sync
        emerge dev-db/sqlite dev-lang/python dev-libs/libbsd dev-libs/libnl dev-libs/libpcre dev-libs/openssl \
                net-libs/libpcap net-wireless/iw net-wireless/lorcon net-wireless/wireless-tools sys-apps/ethtool \
                sys-apps/hwdata sys-apps/hwloc sys-apps/pciutils sys-apps/usbutils sys-libs/zlib app-portage/gentoolkit
        eclean --deep distfiles && eclean --deep packages
        emerge --depclean app-portage/gentoolkit
        rm -fr /var/db/repos/gentoo /etc/portage/binrepos.conf
    fi
elif [ "${ID}" = 'clear-linux-os' ]; then
    echo "[*] Detected Clear Linux (${VERSION_ID})"
    if [ "${STEP}" = 'builder' ]; then
        # Build hostapd
        swupd bundle-add wget c-basic devpkg-openssl devpkg-libnl
        wget https://w1.fi/releases/hostapd-2.10.tar.gz
        tar -zxf hostapd-2.10.tar.gz
        cd hostapd-2.10/hostapd || exit 1
        cp defconfig .config
        make
        make install
        hostapd -v

        # Install the rest of the packages
        swupd bundle-add devpkg-libgcrypt devpkg-hwloc devpkg-libpcap
        # Split it in multiple parts to avoid failure: "Error: Bundle too large by xxxxM"
        swupd bundle-add devpkg-pcre2 devpkg-sqlite-autoconf
        swupd bundle-add ethtool network-basic software-testing
        swupd bundle-add sysadmin-basic wpa_supplicant os-testsuite
                         
    elif [ "${STEP}" = 'stage2' ]; then
        # Break it in multiple steps to avoid the issue mentioned above
        swupd bundle-add libnl openssl devpkg-zlib devpkg-libpcap
        swupd bundle-add sqlite devpkg-pcre2 hwloc network-basic ethtool
        swupd bundle-add sysadmin-basic python-extras
    fi
else
    echo "[!] Unsupported distro: ${ID} - PR welcome"
    exit 1
fi

# shellcheck disable=SC2181
if [ $? -ne 0 ]; then
    echo '[!] ERROR, aborting'
    exit 1
fi

exit 0