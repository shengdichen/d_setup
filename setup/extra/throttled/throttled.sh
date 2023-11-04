source "../../util.sh"

function __install() {
    install "arch" throttled

    service_start -- throttled
}

function __set_conf() {
    echo "Select profile"
    "$(__sudo)" cp \
        "$(find . -maxdepth 1 -type f | grep "\.conf$" | fzf --height="37%")" \
        "/etc/throttled.conf"
}

__install
__set_conf
