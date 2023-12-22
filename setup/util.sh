#!/usr/bin/env dash

dot_dir() {
    echo "${HOME}/dot/dot"
}

bin_dir() {
    echo "${HOME}/dot/bin"
}

__sudo() {
    local s=""
    if [ "$(id -u)" -ne 0 ]; then
        s="sudo"
    fi
    echo "${s}"
}

install() {
    case "${1}" in
        "aur")
            shift && __install_aur "${@}"
            ;;
        "aurhelper")
            shift && __install_aurhelper "${@}"
            ;;
        "arch")
            shift && __install_arch "${@}"
            ;;
        "arch-cache")
            shift && __install_arch_cache "${@}"
            ;;
        "npm")
            shift && __install_npm "${@}"
            ;;
        "pipx")
            shift && __install_pipx "${@}"
            ;;
        *)
            echo "Wrong mode: install()"
            ;;
    esac
}

__is_installed_arch() {
    pacman -Qi "${1}" >/dev/null 2>&1
}

__install_arch() {
    echo "[pacman:(${*})]"

    for p in "${@}"; do
        if ! __is_installed_arch "${p}"; then
            echo "[pacman:${p}] Installing"
            "$(__sudo)" pacman -S --needed "${p}"
        fi
    done
}

__install_aur() {
    __makepkg_filtered() {
        # hide (only) the package-has-been-built error
        # makepkg -src \
        #     2> >(grep -v "ERROR: A package has already been built." 1>&2)
        makepkg -src
    }

    __f() {
        clone_and_stow --cd "$(bin_dir)" --no-stow -- aur "${1}"

        (
            cd "$(bin_dir)/${1}/" || exit
            if __makepkg_filtered "${1}"; then
                echo "[AUR:${p}] Installing"
                echo "select package to install"
                __install_arch_cache "$(
                    find . -maxdepth 1 -type f |
                        grep "\.pkg\.tar\.zst$" |
                        fzf --reverse --height=50%
                )"
            fi
        )
    }

    for p in "${@}"; do
        __f "${p}"
    done
    unset -f __makepkg_filtered __f
}

__install_aurhelper() {
    local helper="paru-bin"
    if ! __is_installed_arch "${helper}"; then
        __install_aur "${helper}"
    fi

    for p in "${@}"; do
        # REF:
        #   https://bbs.archlinux.org/viewtopic.php?id=76218
        if ! pacman -Qm "${p}" >/dev/null 2>&1; then
            echo "[paru:${p}] Installing"
            paru -S --needed "${p}"
        else
            echo "[paru:${p}] Installed already, skipping"
        fi
    done
}

__install_arch_cache() {
    for p in "${@}"; do
        echo "Installing [ARCH-CACHE] ${p}"
        "$(__sudo)" pacman -U --needed "${p}"
    done
}

__install_npm() {
    if [ "${1}" = "--" ]; then shift; fi

    for p in "${@}"; do
        if npm list --global "${p}" 1>/dev/null; then
            echo "[npm:${p}] Installed already, skipping"
        else
            echo "[npm:${p}] Installing"
            npm install --global "${p}"
        fi
    done
}

__install_pipx() {
    local include_deps=""
    if [ "${1}" = "--optional" ]; then
        include_deps="--include-deps"
        shift
    fi
    if [ "${1}" = "--" ]; then shift; fi

    for p in "${@}"; do
        if pipx list --short | grep -q "^${p} "; then
            echo "[pipx:${p}] Installed already, skipping"
        else
            echo "[pipx:${p}] Installing"
            pipx install "${include_deps}" "${p}"
        fi
    done
}

clone_and_stow() {
    local _cd="" _sub=""
    while [ "${#}" -gt 0 ]; do
        case "${1}" in
            "--cd")
                _cd="${2}"
                shift
                shift
                ;;
            "--sub")
                _sub="yes"
                shift
                ;;
            "--")
                shift
                break
                ;;
        esac
    done
    local _repo="${2}" _link _setup_file="setup.sh"
    _link="$(__clone_url "${@}")"

    __clone() {
        if [ "${_sub}" ]; then
            git clone --recursive "${_link}"
        else
            git clone "${_link}"
        fi
    }

    (
        if [ ! "${_cd}" ]; then
            cd "$(dot_dir)"
        elif [ "${_cd}" != "no" ]; then
            cd "${_cd}"
        fi || exit 3

        if [ ! -d "${_repo}" ]; then
            # cater for failed cloning (bad permission, wrong address...)
            if __clone; then
                printf "%s.setup> " "${_repo}"
                if [ -f "${_repo}/${_setup_file}" ]; then
                    (
                        printf "explicit\n"
                        cd "${_repo}" && "./${_setup_file}"
                    )
                else
                    printf "default\n"
                    _stow_nice -R --target="${HOME}" --ignore="\.git.*" "${_repo}"
                fi
                printf "%s.setup> done! " "${_repo}" && read -r _
            fi
        fi
    )
    unset -f __clone
}

__clone_url() {
    local _link
    case "${1}" in
        "self")
            _link="git@github.com:shengdichen/${2}.git"
            ;;
        "github")
            _link="https://github.com/${3}/${2}.git"
            ;;
        "aur")
            _link="https://aur.archlinux.org/${2}.git"
            ;;
    esac

    echo "${_link}"
}

_stow_nice() {
    # REF:
    #   https://github.com/aspiers/stow/issues/65

    # stow "$@" \
    #     2> >(grep -v 'BUG in find_stowed_path? Absolute/relative mismatch' 1>&2)
    stow "${@}"
}

service_start() {
    if [ "${1}" = "--" ]; then shift; fi

    for sv; do
        if systemctl is-active --quiet "${sv}"; then
            echo "[systemd:${sv}] Active already, skipping"
        else
            echo "[systemd:${sv}] Starting"
            systemctl enable --now "${sv}"
        fi
    done
}
