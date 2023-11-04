source "../../util.sh"

function __install() {
    install "pipx" undervolt

    service_start -- throttled
}

__install
