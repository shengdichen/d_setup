#!/usr/bin/env dash

. "../util.sh"

__base() {
    __install arch -- \
        nvidia-utils nvidia-dkms opencl-nvidia cuda
}

__update() {
    "$(__sudo)" pacman -S --noconfirm --needed -- \
        nvidia-utils nvidia-dkms
}

__reload() {
    # REF:
    #   https://stackoverflow.com/questions/43022843/nvidia-nvml-driver-library-version-mismatch

    "$(__sudo)" modprobe -r nvidia_drm
    "$(__sudo)" modprobe -r nvidia_modeset
    "$(__sudo)" modprobe -r nvidia_uvm
    "$(__sudo)" modprobe -r nvidia

    nvidia-smi
}

__link() {
    "$(__sudo)" ln -s "/usr/bin/gcc" "/opt/cuda/bin/."
}

case "${1}" in
    "update")
        __update
        ;;
    "reload")
        __reload
        ;;
    *)
        __base
        ;;
esac
