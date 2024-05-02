#!/usr/bin/env dash

. "../util.sh"

__base() {
    __install arch -- \
        nvidia-dkms opencl-nvidia cuda
}

__update() {
    __install arch -- nvidia-dkms
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

case "${1}" in
    "update")
        __udpate
        ;;
    "reload")
        __reload
        ;;
    *)
        __base
        ;;
esac
