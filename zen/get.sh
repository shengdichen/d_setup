function kernel_version_required() {
    local mode
    if [[ "${1}" == "remote" ]]; then
        mode="S"
    elif [[ "${1}" == "local" ]]; then
        mode="Q"
    fi

    pacman -"${mode}"i zfs-linux-"${2}" | \
    grep "^Depends On" | \
    sed "s/.*linux-${2}=\\(\\S*\\).*/\\1/"
}

function need_update() {
    local ver_remote ver_local
    ver_remote=$(kernel_version_required remote "${1}")
    ver_local=$(kernel_version_required local "${1}")

    [[ "${ver_remote}" != "${ver_local}" ]]
}

function download() {
    for f in "${@:2}"; do
        if [ ! -f "${f}" ]; then
            wget "${1}/${f}"
        fi
    done
}

function uninstall_if_installed() {
    for p in "${@}"; do
        if pacman -Qi "${p}" >/dev/null; then
            sudo pacman -Rns "${p}"
        fi
    done
}

function pipeline_zen() {
    local suffix="-x86_64.pkg.tar.zst"
    local prefixes=("linux-zen" "linux-zen-headers" "linux-zen-docs")
    local version
    version="$(kernel_version_required remote zen)"
    local packages_kernel=()
    for prefix in "${prefixes[@]}"; do
        packages_kernel+=("${prefix}-${version}${suffix}")
    done

    download "https://archive.archlinux.org/packages/l/linux-zen" "${packages_kernel[@]}"
    local packages_zfs=("zfs-linux-zen" "zfs-linux-zen-headers")

    if need_update zen; then
        uninstall_if_installed "${packages_zfs[@]}" "${packages_kernel[@]}"

        sudo pacman -U "${packages_kernel[@]}"
        sudo pacman -S "${packages_zfs[@]}"
    fi
}
pipeline_zen
