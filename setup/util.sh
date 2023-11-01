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

function install() {
    case "${1}" in
        "aur")
            _install_aur "${@:2}"
            ;;
        "arch")
            "$(__sudo)" pacman -S --needed "${@:2}"
            ;;
        "arch-cache")
            _install_arch_cache "${@:2}"
            ;;
        *)
            echo "Wrong mode: install()"
            ;;
    esac
}

function _install_aur() {
    function __f() {
        clone_and_stow --no-stow -- aur "${1}"

        (
            cd "$(bin_dir)/${1}" || exit
            if makepkg -src; then
                echo
                echo "select package to install"
                _install_arch_cache "$(\
                    find . -maxdepth 1 -type f | \
                    grep "\.pkg\.tar\.zst$" | \
                    fzf --reverse --height=50%\
                )"
            fi
        )
    }

    for p in "${@}"; do
        echo "Installing [AUR] ${p}"
        __f "${p}"
    done
    unset -f __f
}

function _install_arch_cache() {
    for p in "${@}"; do
        echo "Installing [ARCH-CACHE] ${p}"
        "$(__sudo)" pacman -U --needed "${p}"
    done
}

function clone_and_stow() {
    local _cd=true _repo _link _sub=false _stow=true
    while (( ${#} > 0 )); do
        case "${1}" in
            "--no-cd" )
                _cd=false
                shift ;;
            "--sub" )
                _sub=true
                shift ;;
            "--no-stow" )
                _stow=false
                shift ;;
            "--" )
                _repo="${3}"
                _link="$(_clone_url "${@:2}")"
                break
        esac
    done

     function __clone() {
        if "${1}"; then
            git clone --recursive "${@:2}"
        else
            git clone "${@:2}"
        fi
    }
    (
        if "${_cd}"; then
            cd "$(dot_dir)" || exit 3
        fi

        if [[ ! -d "${_repo}" ]]; then
            # cater for failed cloning (bad permission, wrong address...)
            if __clone "${_sub}" "${_link}"; then
                if "${_stow}"; then
                    _stow_nice -R --target="${HOME}" --ignore="\.git.*" "${_repo}"
                    echo "Stowing completed"
                fi
            fi
        fi
    )
    unset -f __clone
}

function _clone_url() {
    local repo link
    case "${1}" in
        "self" )
            repo="${2}"
            link="git@github.com:shengdichen/${repo}.git"
            ;;
        "github" )
            repo="${2}"
            link="https://github.com/${3}/${repo}.git"
            ;;
        "aur" )
            repo="${2}"
            link="https://aur.archlinux.org/${repo}.git"
            ;;
    esac

    echo "${link}"
}

function _stow_nice() {
    # REF:
    #   https://github.com/aspiers/stow/issues/65

    stow "$@" \
        2> >(grep -v 'BUG in find_stowed_path? Absolute/relative mismatch' 1>&2)
}
