source "../util.sh"

function __base() {
    install "arch" \
        nvidia-dkms opencl-nvidia cuda
}

__base
