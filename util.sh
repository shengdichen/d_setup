function install() {
    case "$1" in
        "arch")
            pacman -S --needed "${@:2}"
            ;;
        *)
            pacman -S --needed "${@:2}"
            ;;
    esac
}
