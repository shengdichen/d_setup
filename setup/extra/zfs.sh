#!/usr/bin/env bash

. "../util.sh"

__zfs_linux() {
    printf "zfs-linux-%s" "${1}"
}

__pacman() {
    __version() {
        local _flag="Q"
        case "${1}" in
            "--remote")
                _flag="S"
                shift
                ;;
            "--local")
                _flag="Q"
                shift
                ;;
        esac

        pacman -"${_flag}"i -- "${1}" |
            grep "^Version\\s*:" |
            sed "s/^Version\\s*:\\s*\\(\\S*\\)$/\\1/"
    }

    __url() {
        local _package="${1}" _version="${2}"
        local _package_first_char
        _package_first_char="$(printf "%s" "${_package}" | head -c 1)"
        local _file="${_package}-${_version}-x86_64.pkg.tar.zst"

        printf \
            "https://archive.archlinux.org/packages/%s/%s/%s" \
            "${_package_first_char}" \
            "${_package}" \
            "${_file}"
    }

    __uninstall_safe() {
        if [ "${1}" = "--" ]; then shift; fi

        local _packages=()
        for _p in "${@}"; do
            if __is_installed_arch "${_p}"; then
                _packages+=("${_p}")
            fi
        done

        if [ "${#_packages[@]}" -ne 0 ]; then
            sudo pacman -Rns --noconfirm -- "${_packages[@]}"
        fi
    }

    __install_safe() {
        if [ "${1}" = "--" ]; then shift; fi

        local _packages=()
        for _p in "${@}"; do
            if ! __is_installed_arch "${_p}" || __is_outdated -- "${_p}"; then
                _packages+=("${_p}")
            fi
        done

        if [ "${#_packages[@]}" -ne 0 ]; then
            sudo pacman -S --noconfirm -- "${_packages[@]}"
        fi
    }

    __is_outdated() {
        if [ "${1}" = "--" ]; then shift; fi
        pacman -Qu -- "${1}" 1>/dev/null
    }

    case "${1}" in
        "version")
            shift
            __version "${@}"
            ;;
        "url")
            shift
            __url "${@}"
            ;;
        "uninstall")
            shift
            __uninstall_safe "${@}"
            ;;
        "install")
            shift
            __install_safe "${@}"
            ;;
        "outdated")
            shift
            __is_outdated "${@}"
            ;;
    esac
}

pipeline() {
    __linux_version_required() {
        local _flag="S"
        case "${1}" in
            "--remote")
                _flag="S"
                shift
                ;;
            "--local")
                _flag="Q"
                shift
                ;;
        esac

        pacman -"${_flag}"i "$(__zfs_linux "${1}")" |
            grep "^Depends On" |
            sed "s/.*linux-${1}=\\(\\S*\\).*/\\1/"
    }

    sudo pacman -Syy

    local _packages_r=() _packages_u=() _packages_s=()
    local _zfs_utils="zfs-utils" _zfs_linux
    for _kernel in "zen" "lts"; do
        _zfs_linux="$(__zfs_linux "${_kernel}")"
        for _p in "${_zfs_utils}" "${_zfs_linux}"; do
            if ! __is_installed_arch "${_p}"; then
                _packages_s+=("${_p}")
            else
                if __pacman outdated "${_p}"; then
                    _packages_r+=("${_p}")
                    _packages_s+=("${_p}")
                fi
            fi
        done

        _version="$(__linux_version_required "${_kernel}")"
        for _p in \
            "linux-${_kernel}" \
            "linux-${_kernel}-headers" \
            "linux-${_kernel}-docs"; do
            if ! __is_installed_arch "${_p}"; then
                _packages_u+=("$(__pacman url "${_p}" "${_version}")")
            elif ! [ "$(__pacman version "${_p}")" = "${_version}" ]; then
                _packages_r+=("${_p}")
                _packages_u+=("$(__pacman url "${_p}" "${_version}")")
            fi
        done
    done

    if [ ! "${#_packages_r[@]}" -eq 0 ]; then
        sudo pacman -Rns --noconfirm -- "${_packages_r[@]}"
    fi
    if [ ! "${#_packages_u[@]}" -eq 0 ]; then
        sudo pacman -U --noconfirm -- "${_packages_u[@]}"
    fi
    if [ ! "${#_packages_s[@]}" -eq 0 ]; then
        sudo pacman -S --noconfirm -- "${_packages_s[@]}"
    fi
}

__uninstall() {
    for _kernel in "zen" "lts"; do
        __pacman uninstall -- "$(__zfs_linux "${_kernel}")"

        __pacman install -- \
            "linux-${_kernel}" \
            "linux-${_kernel}-headers" \
            "linux-${_kernel}-docs"
    done
    __pacman uninstall -- "zfs-utils"
}

case "${1}" in
    "uninstall")
        __uninstall
        ;;
    *)
        pipeline
        ;;
esac
