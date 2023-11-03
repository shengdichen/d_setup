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

function download() {
    if [ ! -f "${file}" ]; then
        wget "$(__url "${@}")"
    fi
}

function __url() {
    local f="${1}-${2}-x86_64.pkg.tar.zst"
    echo "https://archive.archlinux.org/packages/${1[1]}/${1}/${f}"
}

function download_packages_kernel() {
    for p in "${@:2}"; do
        download "${p}" "${1}"
    done
}

function uninstall_if_installed() {
    for p in "${@}"; do
        if is_installed "${p}"; then
            sudo pacman -Rns "${p}"
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

    local suffix="-x86_64.pkg.tar.zst"
    local packages_kernel=("linux-${kernel}" "linux-${kernel}-headers" "linux-${kernel}-docs")
    local packages_kernel_path=()
    local version
    version=$(kernel_version_required remote "${kernel}")

    download_packages_kernel "${version}" "${packages_kernel[@]}"
    for package in "${packages_kernel[@]}"; do
        packages_kernel_path+=("${package}-${version}${suffix}")
    done

    local packages_zfs=("zfs-linux-${kernel}" "zfs-linux-${kernel}-headers")

    if need_update "${kernel}"; then
        uninstall_if_installed "${packages_zfs[@]}" "${packages_kernel[@]}"

        sudo pacman -U "${packages_kernel_path[@]}"
        if ${install_zfs_header}; then
            sudo pacman -S "${packages_zfs[@]}"
        else
            sudo pacman -S "${packages_zfs[1]}"
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
