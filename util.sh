function dot_dir() {
    echo "$HOME/dot/dot"
}

function bin_dir() {
    echo "$HOME/dot/bin"
}

function __sudo() {
    local SUDO=""
    if (( "$EUID" != 0 )); then
        SUDO=sudo
    fi
    echo "${SUDO}"
}

function install_aur() {
    (
        cd "$(bin_dir)" || exit
        git clone "https://aur.archlinux.org/$1.git"
    )

    (
        cd "$(bin_dir)/$1" || exit
        makepkg -src

        echo
        echo "select package to install from:"
        ls ./*".pkg.tar.zst"
        echo ""

        read -r pkg
        "$(__sudo)" pacman -U "${pkg}"
    )
}

function install() {
    case "$1" in
        "aur")
            install_aur "$2"
            ;;
        "arch")
            "$(__sudo)" pacman -S --needed "${@:2}"
            ;;
        *)
            "$(__sudo)" pacman -S --needed "${@:2}"
            ;;
    esac
}

function clone_url() {
    case "$1" in
        "github" | "GH" )
            echo "git@github.com:shengdichen/$2.git"
            ;;
    esac
}

function clone_and_stow() {
    local remote="$1"
    local local="$2"

    if [[ ! -d ${local} ]]; then
        git clone "${remote}" "${local}"
    fi

    if [[ -d ${local} ]]; then  # cater for failed cloning
        stow -R --target="${HOME}" --ignore="\.git.*" "${local}"
        echo "Stowing completed"
    fi
}

function fetch_and_stow() {
    local local="$1"
    (
        cd "${local}" || exit
        git fetch && git merge main
        stow --restow "$1"
    )
}
