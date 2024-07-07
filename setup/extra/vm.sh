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
    printf "Set UEFI:\n"
    printf "    Edit -> Preferences -> New VM -> x86 Firmware -> UEFI\n"
    printf "Done "
    read -r _

    printf "\n\n"
    printf "Use QEMU (User):\n"
    printf "    File -> Add Connection -> Hypervisor: QEMU/KVM user session -> connect\n"
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

__windows() {
    # NOTE:
    #   0. base
    #   0.1 get iso
    #       REF:
    #       https://massgrave.dev/windows_ltsc_links#download-links
    #       ->  Windows 10/11 IoT Enterprise LTSC
    #   0.2 vm (pre-install)
    #       ram/disk: 20480MB/175GB
    #       CPU: 1 socket, 4 cores, 2 threads
    #
    #   0.3 vm (install)
    #       account: sign in with ms -> "domain join instead"
    #       services: privacy settings -> disable all
    #
    #   1.  windows setup
    #   1.0 base
    #       a.  "windows update" (might need reboot)
    #
    #       b.  activation
    #       ps$ irm https://get.activated.win | iex
    #       ->  [1] HWID
    #
    #       c. firefox-dev
    #
    #   1.1 driver
    #       a. spice
    #       1. download:
    #           https://www.spice-space.org/download.html
    #           -> Guest -> Windows binaries -> Windows SPICE Guest Tools (spice-guest-tools [click here])
    #       2. ps$ ./spice-guest-tools-latest.exe
    #       ->  now able to change resolution and share clipboard
    #       3. vm (should be added automatically): Add Hardware -> Channel -> Name: com.redhat.spice.0
    #
    #       b.  virtio
    #       REF:
    #       https://github.com/virtio-win/kvm-guest-drivers-windows/wiki/Driver-installation
    #       1. download:  virtio-win-<some_version>.iso
    #       2. windows: shutdown
    #       3. vm: Add Hardware -> Storage -> Device type: CDROM device ->
    #       Select or create custom storage (locate virtio)
    #       4. windows: boot
    #       5. windows: This PC -> CD Drive (?:) virtio-win-<some_version> -> ./virtio-win-guest-tools
    #       6. windows: update & shutdown
    #       7. vm: Add Hardware -> Channel -> Name: org.qemu.guest_agent.0
    #
    #   1.2 visual
    #       taskbar: UNshow "task view button" & search
    #       desktop: remove shortcuts; view->UNshow desktop iconds
    #       Home/Personalization/
    #       ->  Background
    #       ->  Colors: Dark & Metal Blue
    #       ->  Start: off: "app list" & recently added
    #       ->  Taskbar: auto hide
    #
    #   1.3 powershell
    #       # Update-Help
    #
    #       REF:
    #       https://stackoverflow.com/questions/2035193/how-to-run-a-powershell-script
    #       # Set-ExecutionPolicy RemoteSigned
    #
    #   1.4 freeze
    #       ps$ Stop-Computer
    #       vm: make snapshot
    #
    #   2. userland
    #   2.0 wsl
    #   base:
    #   REF:
    #   https://learn.microsoft.com/en-us/windows/wsl/install-manual#step-3---enable-virtual-machine-feature
    #   https://superuser.com/questions/1431148/kvm-nested-virtualbox-windows-guest/1589286#1589286
    #   2.0.1. enable windows feature
    #       # Enable-WindowsOptionalFeature -Online -All -FeatureName Microsoft-Windows-Subsystem-Linux
    #       # Enable-WindowsOptionalFeatuupdatere -Online -All -FeatureName VirtualMachinePlatform
    #       reboot:
    #       edit xml:
    #           <cpu mode="custom" match="exact" check="none">
    #               <model fallback="forbid">qemu64</model>
    #               <feature policy="disable" name="hypervisor"/>
    #               topfeature policy="require" name="vmx"/>
    #           </cpu>
    #           <cpu mode="host-model" check="none">
    #               <feature policy="disable" name="hypervisor"/>
    #               <feature policy="require" name="vmx"/>
    #           </cpu>
    #   2.0.2. update
    #       ps$ wsl --update
    #       ps$ wsl --install -d Ubuntu
    #       ps$ wsl --set-default-version 2
    #
    #   2.0.3. arch
    #       a. download:
    #       https://github.com/yuk7/ArchWSL/releases
    #       b.  unpack
    #       ps$ Set-Location ~/Downloads
    #       ps$ Expand-Archive ./Arch.zip
    #       b.  install
    #       ps$ Set-Location Arch
    #       ps$ ./Arch.exe
    #       c.  configure
    #       ps$ ./Arch.exe config --default-user {username}
    #
    #   2.0.4. admin
    #       ps$ wsl --list --verbose
    #       ps$ wsl --setdefault Arch
    #
    #   2.1  office (optional)
    #       REF:
    #       a. download: https://gravesoft.dev/office_c2r_links#english-en-us
    #       ->  O365ProPlus
    #       b. activate:
    #       ps$ irm https://get.activated.win | iex
    #       ->  [2]->[1] install
    #
    #   2.2 scoop
    #
    #   2.3 python
    #       a. install pycharm
    #       https://www.jetbrains.com/pycharm/download/download-thanks.html?platform=windows&code=PCC
    #       b.  install python
    #       https://www.python.org/downloads/windows/
    #       c.  install poetry
    #       (Invoke-WebRequest -Uri https://install.python-poetry.org -UseBasicParsing).Content | py -
    #       https://python-poetry.org/docs/#installing-with-the-official-installer
    #       4.  pyinstaller
    #       C:\Users\shc\AppData\Local\Programs\Python\Python312\Scripts\pip.exe `
    #           install numpy pyinstaller
    #

    (
        #   https://pve.proxmox.com/wiki/Windows_VirtIO_Drivers
        #   https://github.com/virtio-win/virtio-win-pkg-scripts
        local _driver_virtio="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"
        cd "${HOME}/.local/share/libvirt/images/" || exit 3
        wget "${_driver_virtio}"

        printf "\n\n"
        printf "Install drivers:\n"
        printf "1. boot windows with virtio-disk as extra CD-ROM\n"
        printf "2. This PC/virtio-win-.*/virtio-win-guest-tools\n"
        printf "\n\n"
    )
}

libvirt
