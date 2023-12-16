SCRIPT_NAME="$(basename "${0}")"

MOUNT_ROOT="${HOME}/mnt"
MOUNT_MATRIX="m"
DOT_ROOT="${HOME}/dot/dot"
DOT_PRV="d_prv"

_pre() {
    if [ "${EUID}" -eq 0 ]; then
        echo "Must be non-root, (create and) switch to user"
        exit 3
    fi

    sudo pacman -Syu
    sudo pacman -S --needed \
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
}

raw_ssh() {
    if [ -d "${HOME}/.ssh" ]; then
        echo "Found existing ssh-config, skipping"
        return
    fi

    local mount_tmp="${MOUNT_ROOT}/mount_tmp"
    mkdir -p "${mount_tmp}"
    sudo mount /dev/sdb1 "${mount_tmp}"

    local zip_name=".ssh.zip"
    cp -f "${mount_tmp}/x/Dox/sys/${zip_name}" "${HOME}"
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

    if sudo umount "${mount_tmp}"; then
        rmdir "${mount_tmp}"
        echo "Safely unmounted, remove storage now!"
        echo -n "Hit [Enter] when ready:"
        read -r
    else
        echo
        echo "Unmount failed, you might be fine ignoring this though"
    fi
}

clone_setup() {
    local setup_link="shengdichen/d_setup.git"
    (
        cd || exit 3
        # clone from https since we do NOT have ssh yet
        if ! git clone "https://github.com/${setup_link}" dot; then
            echo " Cloning d_setup failed: bad internet?"
            exit 3
        fi

        # for later: when we are done here, we will be able to ssh
        cd dot && git remote set-url origin "git@github.com:${setup_link}"
    )
}

prv() {
    # source of prv
    mkdir -p "${MOUNT_ROOT}/${MOUNT_MATRIX}"
    (
        cd "${MOUNT_ROOT}" || exit 3
        sshfs "ssh_matrix_ext:/" "${MOUNT_MATRIX}" -o "reconnect,idmap=user"
    )

    local branch="main"
    mkdir -p "${DOT_ROOT}/${DOT_PRV}"
    (
        cd "${DOT_ROOT}/${DOT_PRV}" || exit 3
        # specify |-b| to prevent warning for missing default brach name
        git init -b "${branch}"
        git remote add origin "file://${MOUNT_ROOT}/${MOUNT_MATRIX}/home/main/dot/dot/${DOT_PRV}"
        git fetch
        git merge origin/"${branch}"
    )

    # get ready for stowing(-override)
    rm -r "${HOME}/.ssh"
    fusermount -u "${MOUNT_ROOT}/${MOUNT_MATRIX}"
    rmdir "${MOUNT_ROOT}/${MOUNT_MATRIX}"

    (
        cd "${DOT_ROOT}/${DOT_PRV}" && ${SHELL} setup.sh
    )
}

_post() {
    rm "${SCRIPT_NAME}"

    echo "Setup complete, run |~/dot/dot/setup.sh| when ready"
}

_pre
raw_ssh
clone_setup
prv
_post
unset -f _pre raw_ssh clone_setup prv _post
