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
    #       $ irm https://get.activated.win | iex
    #       ->  [1] HWID
    #
    #       c. spice
    #               https://www.spice-space.org/download.html
    #       $ ./spice-guest-tools-latest.exe
    #       ->  now able to change resolution and share clipboard
    #
    #       d.  virtio
    #       REF:
    #       https://github.com/virtio-win/kvm-guest-drivers-windows/wiki/Driver-installation
    #       1. download
    #       2. shutdown
    #       3. vm: add hardware: sata sdrom virtio
    #       4. windows: This PC/CD virtio-win: ./virtio-win-guest-tools
    #       5. shutdown -> vm: Add Hardware/Channel: Name: org.qemu.guest_agent.0
    #
    #   1.1 visual
    #       taskbar: UNshow "task view button" & search
    #       desktop: remove shortcuts; view->UNshow desktop iconds
    #       Home/Personalization/
    #       ->  Background
    #       ->  Colors: Dark & Metal Blue
    #       ->  Start: off: "app list" & recently added
    #       ->  Taskbar: auto hide
    #   1.3 powershell
    #       # Update-Help
    #
    #       REF:
    #       https://stackoverflow.com/questions/2035193/how-to-run-a-powershell-script
    #       # Set-ExecutionPolicy RemoteSigned
    #
    #   $ Stop-Computer;
    #   vm: make snapshot
    #
    #   2.  userland
    #   1.1
    #       a.  firefox-dev
    #
    #       b.  office
    #       REF:
    #       https://gravesoft.dev/office_c2r_links#english-en-us
    #       ->  O365ProPlus
    #       $ irm https://get.activated.win | iex
    #       ->  [2]->[1] install
    #
    #   3.  dev
    #   3.1  wsl
    #   base:
    #   REF:
    #   https://learn.microsoft.com/en-us/windows/wsl/install-manual#step-3---enable-virtual-machine-feature
    #   https://superuser.com/questions/1431148/kvm-nested-virtualbox-windows-guest/1589286#1589286
    #   1.  enable windows feature
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
    #   2.  update
    #       $ wsl.exe --update
    #       $ wsl.exe --install -d Ubuntu
    #       $ wsl.exe --set-default-version 2
    #
    #   3.  arch
    #       a. download:
    #       https://github.com/yuk7/ArchWSL/releases
    #       b.  unpack
    #       $ cd ~/Downloads
    #       $ Expand-Archive ./Arch.zip
    #       b.  install
    #       $ cd Arch
    #       $ ./Arch.exe
    #       c.  configure
    #       win$ Arch.exe config --default-user {username}
    #
    #   4.  admin
    #       $ wsl --list --verbose
    #       $ wsl --setdefault Arch
    #
    # python
    #   1.  install pycharm
    #   https://www.jetbrains.com/pycharm/download/download-thanks.html?platform=windows&code=PCC
    #   2.  install python
    #   https://www.python.org/downloads/windows/
    #   3.  install poetry
    #   (Invoke-WebRequest -Uri https://install.python-poetry.org -UseBasicParsing).Content | py -
    #   https://python-poetry.org/docs/#installing-with-the-official-installer
    #   4.  pyinstaller
    #       C:\Users\shc\AppData\Local\Programs\Python\Python312\Scripts\pip.exe `
    #           install numpy pyinstaller

    #   TODO:
    #       how to add to PATH?

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
