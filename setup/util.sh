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
            __install_aur "${@:2}"
            ;;
        "arch")
            __install_arch "${@:2}"
            ;;
        "arch-cache")
            __install_arch_cache "${@:2}"
            ;;
        "npm")
            __install_npm "${@:2}"
            ;;
        "pipx")
            __install_pipx "${@:2}"
            ;;
        *)
            echo "Wrong mode: install()"
            ;;
    esac
}

function __install_arch() {
    echo "[pacman:(${*})]"

    for p in "${@}"; do
        if ! pacman -Qs "${1}" >/dev/null; then
            echo "[pacman:${1}] Installing"
            pacman -S --needed "${1}"
        fi
    done
}

function __install_aur() {
    function __makepkg_filtered() {
        # hide (only) the package-has-been-built error
        makepkg -src \
            2> >(grep -v "ERROR: A package has already been built." 1>&2)
    }

    function __f() {
        clone_and_stow --cd "$(bin_dir)" --no-stow -- aur "${1}"

        (
            cd "$(bin_dir)/${1}/" || exit
            if __makepkg_filtered "${1}"; then
                echo "[AUR:${p}] Installing"
                echo "select package to install"
                __install_arch_cache "$(\
                    find . -maxdepth 1 -type f | \
                    grep "\.pkg\.tar\.zst$" | \
                    fzf --reverse --height=50%\
                )"
            fi
        )
    }

    for p in "${@}"; do
        __f "${p}"
    done
    unset -f __makepkg_filtered __f
}

function __install_arch_cache() {
    for p in "${@}"; do
        echo "Installing [ARCH-CACHE] ${p}"
        "$(__sudo)" pacman -U --needed "${p}"
    done
}

function __install_npm() {
    for p in "${@}"; do
        if npm list --global "${p}" 1>/dev/null; then
            echo "[npm:${p}] Installed already, skipping"
        else
            echo "[npm:${p}] Installing"
            npm install --global "${p}"
        fi
    done
}

function __install_pipx() {
    local _optional=false _packs
    while (( ${#} > 0 )); do
        case "${1}" in
            "--optional" )
                _optional=true
                shift ;;
            "--" )
                _packs=("${@:2}")
                break
        esac
    done

    for p in "${_packs[@]}"; do
        if pipx list --short | grep -q "^${p} "; then
            echo "[pipx:${p}] Installed already, skipping"
        else
            echo "[pipx:${p}] Installing"
            if "${_optional}"; then
                pipx install --include-deps "${p}"
            else
                pipx install "${p}"
            fi
        fi
    done
}

function clone_and_stow() {
    local _cd _repo _link _sub=false _stow=true
    while (( ${#} > 0 )); do
        case "${1}" in
            "--cd" )
                _cd="${2}"
                shift; shift ;;
            "--sub" )
                _sub=true
                shift ;;
            "--no-stow" )
                _stow=false
                shift ;;
            "--" )
                _repo="${3}"
                _link="$(__clone_url "${@:2}")"
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
        if [[ -z "${_cd}" ]]; then
            cd "$(dot_dir)"
        elif [[ "${_cd}" != "no" ]]; then
            cd "${_cd}"
        fi || exit 3

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

function __clone_url() {
    local _link
    case "${1}" in
        "self" )
            _link="git@github.com:shengdichen/${2}.git"
            ;;
        "github" )
            _link="https://github.com/${3}/${2}.git"
            ;;
        "aur" )
            _link="https://aur.archlinux.org/${2}.git"
            ;;
    esac

    echo "${_link}"
}

function _stow_nice() {
    # REF:
    #   https://github.com/aspiers/stow/issues/65

    stow "$@" \
        2> >(grep -v 'BUG in find_stowed_path? Absolute/relative mismatch' 1>&2)
}

function service_start() {
    local _services
    while (( ${#} > 0 )); do
        case "${1}" in
            "--" )
                _services=("${@:2}")
                break
        esac
    done

    for s in "${_services[@]}"; do
        if systemctl is-active --quiet "${s}"; then
            echo "[systemd:${s}] Active already, skipping"
        else
            echo "[systemd:${s}] Starting"
            systemctl enable --now "${1}"
        fi
    done
}
