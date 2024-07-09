#!/usr/bin/env dash

. "../util.sh"

libvirt() {
    # REF:
    #   https://wiki.archlinux.org/title/Libvirt
    __install arch -- \
        libvirt qemu-full \
        virt-manager \
        iptables-nft dnsmasq \
        openbsd-netcat \
        edk2-ovmf

    printf "\n\n"
    echo "Set UEFI:"
    echo "    Edit -> Preferences -> x86 Firmware -> UEFI"
    printf "Done "
    read -r _
}

libvirt_admin() {
    local libvirt_gr="libvirt"
    if ! id -nG "${USER}" | grep -qw "${libvirt_gr}"; then
        printf "\n\n"
        printf "Adding myself [%s] to %s-group: " "${USER}" "${libvirt_gr}"
        read -r _
        "$(__sudo)" usermod -aG "${libvirt_gr}" "${USER}"

        printf "\n\n"
        printf "Must (re)login before using libvirt: "
        read -r _
    fi

    service_start -- libvirtd.service virtlogd.service
}

libvirt
