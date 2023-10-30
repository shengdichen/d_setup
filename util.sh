function dot_dir() {
    local d="${HOME}/dot/dot"
    mkdir -p "${d}"
    echo "${d}"
}

function bin_dir() {
    local d="${HOME}/dot/bin"
    mkdir -p "${d}"
    echo "${d}"
}

function __sudo() {
    local SUDO=""
    if (( "$EUID" != 0 )); then
        SUDO=sudo
    fi
    echo "${SUDO}"
}

function install_arch_cache() {
    for p in "${@}"; do
        echo "Installing [ARCH-CACHE] ${p}"
        "$(__sudo)" pacman -U --needed "${p}"
    done
}

function install_aur() {
    (
        cd "$(bin_dir)" || exit
        clone aur "${1}"
    )

    (
        cd "$(bin_dir)/${1}" || exit
        makepkg -src

        echo
        echo "select package to install"
        install_arch_cache "$(\
            find . -maxdepth 1 -type f | \
            grep "\.pkg\.tar\.zst$" | \
            fzf --reverse --height=50%\
        )"
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
        "arch-cache")
            install_arch_cache "${@:2}"
            ;;
        *)
            "$(__sudo)" pacman -S --needed "${@:2}"
            ;;
    esac
}

function clone() {
    local repo link
    case "${1}" in
        "github" | "GH" )
            repo=${2}
            link="git@github.com:shengdichen/${repo}.git"
            ;;
        "aur" )
            repo=${2}
            link="https://aur.archlinux.org/${repo}.git"
            ;;
    esac
    if [[ ! -d ${repo} ]]; then
        git clone "${link}"
    fi
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
