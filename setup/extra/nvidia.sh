#!/usr/bin/env dash

. "../util.sh"

__base() {
    install "arch" \
        nvidia-dkms opencl-nvidia cuda
}

__base
unset -f __base
