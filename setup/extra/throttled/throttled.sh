source "../../util.sh"

function __install() {
    install "arch" throttled

    service_start -- throttled
}

__install
