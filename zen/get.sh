function get_zen_version() {
    version=$(
        pacman -Si zfs-linux-zen | \
        grep "^Depends On" | \
        sed "s/.*linux-zen=\\(\\S*\\).*/\\1/" \
    )

    echo "${version}"
}

function package_name_zen() {
    echo "linux-zen-""${1}""-x86_64.pkg.tar.zst"
}

function package_name_zen_headers() {
    echo "linux-zen-headers-""${1}""-x86_64.pkg.tar.zst"
}

function package_name_zen_docs() {
    echo "linux-zen-docs-""${1}""-x86_64.pkg.tar.zst"
}

function download() {
    if [ ! -f "${1}" ]; then
        wget "https://archive.archlinux.org/packages/l/linux-zen/""${1}"
    fi
    if [ ! -f "${2}" ]; then
        wget "https://archive.archlinux.org/packages/l/linux-zen/""${2}"
    fi
    if [ ! -f "${3}" ]; then
        wget "https://archive.archlinux.org/packages/l/linux-zen/""${3}"
    fi
}

function install() {
    zfs_zen="zfs-linux-zen"
    zfs_zen_headers="${zfs_zen}""-headers"

    if pacman -Qi "${zfs_zen}" >/dev/null; then
        echo "not have zfs-zen"
    fi
    # TODO: skip removal of uninstalled package if:
    #   1.  not yet installed
    #   2.  no new download
    uninstall_if_installed "${zfs_zen}"
    uninstall_if_installed "${zfs_zen_headers}"

    pacman -Rns "${zfs_zen}" "${zfs_zen_headers}"
    pacman -Rns linux-zen linux-zen-headers linux-zen-docs

    pacman -U "${1}" "${2}" "${3}"
    pacman -S "${zfs_zen}" "${zfs_zen_headers}"
}

function uninstall_if_installed() {
    package="$1"

    if pacman -Qi "${package}" >/dev/null; then
        pacman -Rns "${package}"
    fi
}

function pipeline_zen() {
    version="$(get_zen_version)"

    package_zen="$(package_name_zen "${version}")"
    package_zen_headers="$(package_name_zen_headers "${version}")"
    package_zen_docs="$(package_name_zen_docs "${version}")"

    download "${package_zen}" "${package_zen_headers}" "${package_zen_docs}"
    install "${package_zen}" "${package_zen_headers}" "${package_zen_docs}"
}

pipeline_zen
