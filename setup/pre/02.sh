#!/usr/bin/env dash

SCRIPT_NAME="$(basename "${0}")"

MOUNT_ROOT="${HOME}/mnt"
MOUNT_MATRIX="m"
DOT_ROOT="${HOME}/dot/dot"
DOT_PRV="d_prv"

_pre() {
    if [ "$(id -u)" -eq 0 ]; then
        echo "Must be non-root, (create and) switch to user"
        exit 3
    fi

    sudo pacman -Syu
    sudo pacman -S --needed \
        fzf \
        openssh git stow \
        sshfs fuse2 unzip

    if [ -d "${HOME}/.ssh" ]; then
        rm -r "${HOME}/.ssh"
    fi

    if [ -d "${HOME}/dot" ]; then
        (
            cd "${DOT_ROOT}" || exit 3
            if [ -d "${DOT_PRV}" ]; then
                stow -D "${DOT_PRV}"
            fi
        )
    fi
    rm -rf "${HOME}/dot"

    clear
}

raw_ssh() {
    printf "ssh-raw> start\n\n"

    if [ -d "${HOME}/.ssh" ]; then
        echo "Found existing ssh-config, skipping"
        return
    fi

    local zip_name=".ssh.zip"
    if [ ! -f "${zip_name}" ]; then
        local mount_tmp="${MOUNT_ROOT}/mount_tmp"
        mkdir -p "${mount_tmp}"

        local disk
        echo "select source-disk"
        disk="$(lsblk -o PATH,FSTYPE,SIZE,MOUNTPOINTS | fzf --reverse --height=30% | awk '{ print $1 }')"

        if sudo mount "${disk}" "${mount_tmp}"; then
            if ! cp -f "${mount_tmp}/x/Dox/sys/${zip_name}" "${HOME}"; then
                echo "[ssh-conf] not found on [${disk}], exiting"
                exit 3
            fi
        else
            echo
            echo "[ssh-conf] neither local nor on usb. Exiting"
            echo
            exit 3
        fi
    fi

    (
        cd || exit 3
        if unzip "${zip_name}"; then
            rm "${zip_name}"
            cd "./.ssh" && ${SHELL} "setup.sh"
        else
            echo "Wrong password for ssh, exiting"
            exit 3
        fi
    )

    echo
    if sudo umount "${mount_tmp}"; then
        rmdir "${mount_tmp}"
        printf "Safely unmounted, remove storage now: "
    else
        printf "Unmount failed, you might be fine ignoring this though "
    fi

    printf "\n\n"
    printf "ssh-raw> done " && read -r _ && clear
}

get_d_setup() {
    printf "d_setup> start\n\n"

    local setup_link="shengdichen/d_setup.git"
    (
        cd || exit 3
        if ! git clone "git@github.com:${setup_link}" dot; then
            printf "\n\n"
            printf "d_setup> clone: failed (bad internet?) "
            exit 3
        else
            printf "\n\n"
            printf "d_setup> done " && read -r _ && clear
        fi
    )
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

_pre
raw_ssh
get_d_setup
get_prv
_post
unset -f _pre raw_ssh get_d_setup get_prv _post
