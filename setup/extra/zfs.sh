function __is_installed() {
    pacman -Qs "${1}" >/dev/null
}

function __zfs() {
    echo "zfs-linux-${1}"
}

function __linux_version_required() {
    local flag
    if [[ "${1}" == "remote" ]]; then
        flag="S"
    elif [[ "${1}" == "local" ]]; then
        flag="Q"
    fi

    pacman -"${flag}"i "$(__zfs "${2}")" | \
    grep "^Depends On" | \
    sed "s/.*linux-${2}=\\(\\S*\\).*/\\1/"
}

function __need_install() {
    if __is_installed "$(__zfs "${1}")"; then
        [[
            "$(__linux_version_required "remote" "${1}")" !=
            "$(__linux_version_required "local" "${1}")"
        ]]
    else
        true
    fi
}

function __uninstall_if_installed() {
    for p in "${@}"; do
        if __is_installed "${p}"; then
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

    if __need_install "${kernel}"; then
        __install "${kernel}" "${install_zfs_header}"
    fi
}

function __install() {
    local _linux=("linux-${1}" "linux-${1}-headers" "linux-${1}-docs")
    local _zfs=("zfs-linux-${1}" "zfs-utils") _zfs_header="zfs-linux-${1}-headers"

    __uninstall_if_installed "${_zfs[@]}" "${_zfs_header}" "${_linux[@]}"

    __install_linux "$(__linux_version_required remote "${1}")" "${_linux[@]}"
    sudo pacman -S --noconfirm "${_zfs[@]}"
    if ${2}; then
        sudo pacman -S --noconfirm "${_zfs_header}"
    fi
}

function __install_linux() {
    local urls=()
    for p in "${@:2}"; do
        urls+=("$(__url "${p}" "${1}")")
    done
    sudo pacman -U --noconfirm "${urls[@]}"
}

function __url() {
    local f="${1}-${2}-x86_64.pkg.tar.zst"
    echo "https://archive.archlinux.org/packages/${1[1]}/${1}/${f}"
}

function main() {
    case "${1}" in
        "zen" | "lts" )
            pipeline -k "${1}";;
        * )
            for k in "zen" "lts"; do
                pipeline -k "${k}"
            done
            ;;
    esac
}
main "${@}"
