#!/usr/bin/env dash

SCRIPT_NAME="$(basename "${0}")"

MOUNT_ROOT="${HOME}/mnt"
MOUNT_MATRIX="m"
DOT_ROOT="${HOME}/dot/dot"
DOT_PRV="d_prv"

__start() {
    printf "%s> START " "${1}"
}

__error() {
    printf "%s [exiting]\n" "${1}"
    printf "\n"
    exit 3
}

__done() {
    printf "%s> DONE " "${1}" && read -r _
    clear
}

_pre() {
    if [ "$(id -u)" -eq 0 ]; then
        __error "Must be non-root, (create and) switch to user"
    fi

    if ! (sudo pacman -Syy &&
        sudo pacman -S --needed \
            fzf \
            openssh git stow \
            sshfs fuse2 unzip >/dev/null); then
        __error "pacman-install failed; bad internet?"
    fi

    if [ -d "${HOME}/.ssh" ]; then
        rm -r "${HOME}/.ssh"
    fi
    if [ -d "${DOT_ROOT}/${DOT_PRV}" ]; then
        (cd "${DOT_ROOT}" && stow -D "${DOT_PRV}")
    fi
    rm -rf "${HOME}/dot"
}

raw_ssh() {
    printf "ssh-raw> start\n\n"

    if [ -d "${HOME}/.ssh" ]; then
        printf "Found existing ssh-config, skipping\n"
        return
    fi

    local mount_tmp="" disk=""
    local ssh_zip=".ssh.zip"
    if [ -f "${ssh_zip}" ]; then
        printf "found existing [%s], using it" "${ssh_zip}"
    else
        mount_tmp="${MOUNT_ROOT}/mount_tmp"
        mkdir -p "${mount_tmp}"

        printf "select source-disk\n"
        disk="$(lsblk -o PATH,LABEL,FSTYPE,SIZE,MOUNTPOINTS | fzf --reverse --height=30% | awk '{ print $1 }')"

        if ! sudo mount "${disk}" "${mount_tmp}"; then
            __error "mount> [${disk}] failed"
        else
            if ! cp -f "${mount_tmp}/x/Dox/sys/${ssh_zip}" "${HOME}"; then
                __error "[ssh-conf] not found on [${disk}]"
            fi
        fi
    fi

    printf "\n\n"

    if ! (
        cd || exit 3
        if unzip "${ssh_zip}"; then
            rm "${ssh_zip}"
            cd "./.ssh" && ${SHELL} "setup.sh"
        else
            false
        fi
    ); then
        __error "wrong password for ssh"
    fi

    printf "\n\n"

    if [ "${mount_tmp}" ]; then
        if sudo umount "${mount_tmp}"; then
            rmdir "${mount_tmp}"
            printf "umount-[%s]> success; remove storage now: " "${disk}"
        else
            lsblk
            printf "\n\n"
            printf "umount-[%s]> failed, you might be fine ignoring this though: " "${disk}"
        fi
        read -r _
    fi

    printf "\n\n"
    __done "ssh-raw"
}

get_d_setup() {
    __start "d_setup"

    local _link="shengdichen/d_setup.git"
    if ! (
        cd || exit 3
        if ! git clone "git@github.com:${_link}" dot; then
            false
        fi
    ); then
        __error "clone: ${_link} (bad internet?)"
    else
        __done "d_setup"
    fi
}

get_prv() {
    printf "prv> start\n\n"

    # source of prv
    mkdir -p "${MOUNT_ROOT}/${MOUNT_MATRIX}"
    local ssh_profile_source="ssh_matrix_ext"
    (
        cd "${MOUNT_ROOT}" || exit 3
        while true; do
            sshfs "${ssh_profile_source}:/" "${MOUNT_MATRIX}" -o "reconnect,idmap=user"
            if mount | grep "${ssh_profile_source}"; then
                break
            else
                echo "prv.sshfs-mount> failed to mount profile [${ssh_profile_source}], retrying"
                sleep 3
            fi
        done
        printf "\n\n"
        printf "prv> mount-source: done " && read -r _ && clear
    )

    (
        cd "${DOT_ROOT}" || exit 3
        # specify |-b| to prevent warning for missing default brach name
        if ! git clone -b main "file://${MOUNT_ROOT}/${MOUNT_MATRIX}/home/main/dot/dot/${DOT_PRV}" "${DOT_PRV}"; then
            echo "clone> prv: failed, exiting"
            exit 3
        else
            printf "\n\n"
            printf "prv> clone: done " && read -r _ && clear
        fi
    )

    # get ready for stowing(-override)
    rm -r "${HOME}/.ssh"
    fusermount -u "${MOUNT_ROOT}/${MOUNT_MATRIX}"
    rmdir "${MOUNT_ROOT}/${MOUNT_MATRIX}"

    (
        cd "${DOT_ROOT}/${DOT_PRV}" || exit 3
        if ! ./"setup.sh"; then
            echo "prv.setup> failed, exiting"
            exit 3
        else
            printf "\n\n"
            printf "prv> setup: done " && read -r _ && clear
        fi
    )
}

_post() {
    rm "${SCRIPT_NAME}"

    printf "pre-02> done: " && read -r _ && clear

    local _input
    printf "post-setup? [C]onfirm, [q]uit " && read -r _input
    if [ "${_input}" = "q" ]; then
        echo "manually run"
        echo "    \$ sh ~/dot/setup/post/setup.sh"
        echo "when ready, exiting"
    else
        (
            cd "${HOME}/dot/setup/post" || exit 3
            "./setup.sh"
        )
    fi
}

case "${1}" in
    "--clean")
        _pre
        ;;
    "--full")
        if _pre; then
            clear
            if raw_ssh && get_d_setup && get_prv; then
                clear
                _post
            fi
        fi
        ;;
    *)
        printf "try --clean or --full\n"
        ;;
esac
unset -f _pre raw_ssh get_d_setup get_prv _post
