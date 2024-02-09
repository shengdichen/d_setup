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

__install() {
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
    if [ "${?}" -ne 0 ]; then
        printf "\n"
        exit 3
    fi
}

__report() {
    printf "%s> %s" "${1}" "${2}"
    case "${3}" in
        "skip")
            printf ": skipping"
            ;;
        "done")
            printf ": done!"
            ;;
        "install")
            printf ": installing"
            ;;
        "error")
            printf ": error -> %s" "${4}"
            ;;
        *)
            printf "%s" "${3}"
            ;;
    esac
    printf "\n"
}

__is_installed_arch() {
    pacman -Qi "${1}" >/dev/null 2>&1
}

__install_arch() {
    local _report="yes" _confirm="yes"
    while [ "${#}" -gt 0 ]; do
        case "${1}" in
            "--no-report")
                _report=""
                shift
                ;;
            "--no-confirm")
                _confirm=""
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    if [ "${1}" = "--" ]; then shift; fi
    if [ "${_report}" ]; then
        __report pacman "[${*}]"
    fi

    for p in "${@}"; do
        if ! __is_installed_arch "${p}"; then
            if [ "${_report}" ]; then
                __report pacman "${p}" "install"
            fi
            if [ "${_confirm}" ]; then
                "$(__sudo)" pacman -S --needed "${p}"
            else
                "$(__sudo)" pacman -S --needed --noconfirm "${p}"
            fi
        fi
    done
}

__install_aur() {
    __install_one() {
        if __clone_smart --name "${1}" --url "$(__clone_url aur "${1}")"; then
            (
                cd "${1}" || exit 3
                if
                    if ! find . -maxdepth 1 -type f | grep --quiet "\.pkg\.tar\.zst$"; then
                        makepkg -src
                    fi
                then
                    __report AUR "${1}" ": select package: "
                    __install_arch_cache "$(
                        find . -maxdepth 1 -type f |
                            grep "\.pkg\.tar\.zst$" |
                            fzf --reverse --height=50%
                    )"
                fi
            )
        fi
    }

    if [ "${1}" = "--" ]; then shift; fi
    (
        cd "$(bin_dir)" || exit 3
        for p in "${@}"; do
            if ! __is_installed_arch "${p}"; then
                __install_one "${p}"
            else
                __report AUR "${1}" "skip"
            fi
        done
    )

    unset -f __install_one
}

__install_arch_cache() {
    if [ "${1}" = "--" ]; then shift; fi
    for p in "${@}"; do
        __report AUR-cache "${p}" "install"
        "$(__sudo)" pacman -U --needed "${p}"
    done
}

__install_aurhelper() {
    __install_aur -- "paru-bin"

    local _confirm="yes"
    if [ "${1}" = "--no-confirm" ]; then
        _confirm=""
        shift
    fi
    if [ "${1}" = "--" ]; then shift; fi

    for p in "${@}"; do
        # REF:
        #   https://bbs.archlinux.org/viewtopic.php?id=76218
        if ! pacman -Qm "${p}" >/dev/null 2>&1; then
            __report paru "${p}" "install"
            if [ "${_confirm}" ]; then
                paru -S --needed "${p}"
            else
                paru -S --needed --skipreview --noconfirm "${p}"
            fi
        else
            __report paru "${p}" "skip"
        fi
    done
}

__install_npm() {
    __install_arch --no-report -- "npm"

    if [ "${1}" = "--" ]; then shift; fi

    for p in "${@}"; do
        if ! npm list --global "${p}" 1>/dev/null; then
            __report npm "${p}" "install"
            npm install --global "${p}"
        else
            __report npm "${p}" "skip"
        fi
    done
}

__install_pipx() {
    __install_arch --no-report -- "python-pipx"

    local include_deps=""
    if [ "${1}" = "--optional" ]; then
        include_deps="yes"
        shift
    fi
    if [ "${1}" = "--" ]; then shift; fi

    for p in "${@}"; do
        if ! pipx list --short | grep -q "^${p} "; then
            __report pipx "${p}" "install"
            if [ "${include_deps}" ]; then
                pipx install "--include-deps" "${p}"
            else
                pipx install "${p}"
            fi
        else
            __report pipx "${p}" "skip"
        fi
    done
}

__clone_smart() {
    local _sub="" _root="" _name="" _url=""
    while [ "${#}" -gt 0 ]; do
        case "${1}" in
            "--sub")
                _sub="yes"
                shift
                ;;
            "--root")
                _root="${2}"
                shift
                shift
                ;;
            "--name")
                _name="${2}"
                shift
                shift
                ;;
            "--url")
                _url="${2}"
                shift
                shift
                ;;
            *)
                __report clone "${_name}" error "unintelligible option"
                exit 3
                ;;
        esac
    done

    (
        if [ "${_root}" ]; then
            cd "${_root}" || exit 3
        fi
        if [ ! -d "${_name}" ]; then
            if ! (
                if [ "${_sub}" ]; then
                    git clone --recursive "${_url}"
                else
                    git clone "${_url}"
                fi
            ); then
                __report clone "${_name}" error "bad network / url maybe?"
                exit 3
            fi
        fi
    )
}

dotfile() {
    local _sub=""
    if [ "${1}" = "--sub" ]; then
        _sub="yes"
        shift
    fi
    if [ "${1}" = "--" ]; then shift; fi

    local setup_file="setup.sh"

    __do_one() {
        local url
        url="$(__clone_url self "${1}")"
        if (
            if [ "${_sub}" ]; then
                __clone_smart --sub --name "${1}" --url "${url}"
            else
                __clone_smart --name "${1}" --url "${url}"
            fi
        ); then
            if [ -f "${1}/${setup_file}" ]; then
                (
                    __report "dot-explicit" "${1}"
                    cd "${1}" && "./${setup_file}"
                )
            else
                __report "dot-default" "${1}"
                _stow_nice -R "${1}"
            fi
        fi
    }

    (
        cd "$(dot_dir)" || exit 3
        for repo in "${@}"; do
            __do_one "${repo}"
        done
    )

    unset -f __do_one
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
        if ! systemctl is-active --quiet "${sv}"; then
            __report systemd-start "${sv}" ": starting"
            systemctl enable --now "${sv}"
        else
            __report systemd-start "${sv}" "skip"
        fi
    done
}
