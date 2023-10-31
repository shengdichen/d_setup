function dot_dir() {
    echo "${HOME}/dot/dot"
}

function bin_dir() {
    echo "${HOME}/dot/bin"
}

function __sudo() {
    local s=""
    if (( EUID != 0 )); then
        s=sudo
    fi
    echo "${s}"
}

function install_arch_cache() {
    for p in "${@}"; do
        echo "Installing [ARCH-CACHE] ${p}"
        "$(__sudo)" pacman -U --needed "${p}"
    done
}

function install_aur() {
    function __f() {
        (cd "$(bin_dir)" && clone aur "${1}")

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

    for p in "${@}"; do
        echo "Installing [AUR] ${p}"
        __f "${p}"
    done
    unset -f __f
}

function install() {
    case "${1}" in
        "aur")
            install_aur "${@:2}"
            ;;
        "arch")
            "$(__sudo)" pacman -S --needed "${@:2}"
            ;;
        "arch-cache")
            install_arch_cache "${@:2}"
            ;;
        *)
            echo "Wrong mode: install()"
            ;;
    esac
}

function clone() {
    local repo link
    case "${1}" in
        "self" )
            repo=${2}
            link="git@github.com:shengdichen/${repo}.git"
            ;;
        "github" )
            repo=${3}
            link="git@github.com:${2}/${repo}.git"
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

function _stow_nice() {
    # REF:
    #   https://github.com/aspiers/stow/issues/65

    stow "$@" \
        2> >(grep -v 'BUG in find_stowed_path? Absolute/relative mismatch' 1>&2)
}

function clone_and_stow() {
    (
        cd "$(dot_dir)" || exit 3

        # cater for failed cloning (bad permission, wrong address...)
        if clone "${1}" "${2}"; then
            _stow_nice -R --target="${HOME}" --ignore="\.git.*" "${2}"
            echo "Stowing completed"
        fi
    )
}

function fetch_and_stow() {
    (
        cd "${1}" || exit
        git fetch && git merge main
        _stow_nice --restow "${1}"
    )
}