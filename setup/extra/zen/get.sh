function is_installed() {
    pacman -Qs "${1}" >/dev/null
}

function kernel_version_required() {
    local package="zfs-linux-${2}"

    function __f() {
        pacman -"${1}"i "${package}" | \
        grep "^Depends On" | \
        sed "s/.*linux-${2}=\\(\\S*\\).*/\\1/"
    }

    if [[ "${1}" == "remote" ]]; then
        __f "S" "${2}"
    elif [[ "${1}" == "local" ]]; then
        if is_installed "${package}"; then
            __f "Q" "${2}"
        else
            echo "placeholder"
        fi
    fi

    unset -f __f
}

function need_update() {
    if is_installed "${1}"; then
        return
    fi

    local ver_remote ver_local
    ver_remote=$(kernel_version_required remote "${1}")
    ver_local=$(kernel_version_required local "${1}")

    [[ "${ver_remote}" != "${ver_local}" ]]
}

function __install_kernel() {
    local urls=()
    for p in "${@:2}"; do
        urls+=("$(__url "${p}" ${1})")
    done
    sudo pacman -U "${urls[@]}"
}

function __url() {
    local f="${1}-${2}-x86_64.pkg.tar.zst"
    echo "https://archive.archlinux.org/packages/${1[1]}/${1}/${f}"
}

function uninstall_if_installed() {
    for p in "${@}"; do
        if is_installed "${p}"; then
            sudo pacman -Rns --noconfirm "${p}"
        fi
    done
}

function pipeline() {
    local kernel install_zfs_header=false
    while (( ${#} > 0 )); do
        case "${1}" in
            "-k" | "--kernel" )
                kernel="${2}"
                shift; shift
                ;;
            "--install-zfs-header" )
                install_zfs_header=true
                shift
                ;;
        esac
    done

    local packages_kernel=("linux-${kernel}" "linux-${kernel}-headers" "linux-${kernel}-docs")
    local _zfs_kernel="zfs-linux-${kernel}" _zfs_header="zfs-linux-${kernel}-headers"

    if need_update "${kernel}"; then
        uninstall_if_installed "${_zfs_kernel}" "${_zfs_header}" "${packages_kernel[@]}"

        __install_kernel "$(kernel_version_required remote "${kernel}")" "${packages_kernel[@]}"
        sudo pacman -S "${_zfs_kernel}"
        if ${install_zfs_header}; then
            sudo pacman -S "${_zfs_header}"
        fi
    fi
}

function main() {
    case "${1}" in
        "zen" | "lts" )
            pipeline -k "${1}";;
        * )
            pipeline -k "zen"
            pipeline -k "lts"
            ;;
    esac
}
main "${@}"
