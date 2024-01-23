#!/usr/bin/env dash

SCRIPT_NAME="$(basename "${0}")"

MOUNT_ROOT="${HOME}/mnt"
MOUNT_MATRIX="m"
DOT_ROOT="${HOME}/dot/dot"
DOT_PRV="d_prv"

__start() {
    printf "%s> START \n" "${1}"
    printf "\n"

}

__error() {
    printf "\n"
    printf "%s [exiting]\n" "${1}"
    exit 3
}

__done() {
    printf "\n"
    printf "%s> DONE " "${1}" && read -r _
    clear
}

__yes_or_no() {
    local _input
    while true; do
        printf "%s: [y]es; [n]o? " "${1}"
        read -r _input

        case "${_input}" in
            "y" | "yes")
                return 0
                ;;
            "n" | "no")
                return 1
                ;;
        esac
    done
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
        if __yes_or_no "remove ~/.ssh"; then
            rm -r "${HOME}/.ssh"
        fi
    fi
    if [ -d "${DOT_ROOT}/${DOT_PRV}" ]; then
        (cd "${DOT_ROOT}" && stow -D "${DOT_PRV}")
    fi
    rm -rf "${HOME}/dot"
}

__unmount() {
    while mount | grep "on ${1}" >/dev/null 2>&1; do
        if ! sudo umount "${1}"; then
            lsblk
            printf "\n"
            printf "umount-[%s]> failed; retry: " "${1}"
            read -r _
            printf "\n"
        fi
    done
    [ -d "${1}" ] && rm -r "${1}"
}

raw_ssh() {
    if [ -d "${HOME}/.ssh" ]; then
        printf "Found existing ssh-config, skipping\n"
        return
    fi

    local _ssh_zip=".ssh.zip"
    local _mountpt="${MOUNT_ROOT}/mount_tmp"
    __start "ssh-raw"

    __copy_zip() {
        mkdir -p "${_mountpt}"
        local _ssh_zip_path="${_mountpt}/x/Dox/sys/${_ssh_zip}"

        local _disk=""
        printf "select source-disk\n\n"
        _disk="$(lsblk -o PATH,LABEL,FSTYPE,SIZE,MOUNTPOINTS | fzf --reverse --height=30% | awk '{ print $1 }')"

        if ! sudo mount "${_disk}" "${_mountpt}"; then
            __error "mount> [${_disk}] failed"
        fi
        if [ ! -f "${_ssh_zip_path}" ]; then
            __unmount "${_mountpt}"
            __error "[${_ssh_zip}] not found on [${_disk}]"
        elif ! cp -f "${_mountpt}/x/Dox/sys/${_ssh_zip}" "${HOME}"; then
            __unmount "${_mountpt}"
            __error "[${_ssh_zip}] copying failed, bad permission?"
        fi
    }

    __decrypt() {
        local _ssh_dir="./.ssh"
        # clear out residuals, if any, from previous attempt(s)
        [ -d "${_ssh_dir}" ] && rm -r "${_ssh_dir}"
        (
            cd || exit 3
            if unzip "${_ssh_zip}"; then
                rm "${_ssh_zip}" &&
                    cd "${_ssh_dir}" && ${SHELL} "setup.sh" &&
                    __unmount "${_mountpt}"
            else
                echo "case 2"
                # NOTE:
                #   1. deliberately not remove ssh-zip for reuse
                #   2. ssh-dir is created by unzip even if unpacking failed
                rm -r "${_ssh_dir}" && __unmount "${_mountpt}"
                __error "ssh-decrypt: wrong password?"
            fi
        )
    }

    if [ -f "${_ssh_zip}" ]; then
        printf "found existing [%s], using it\n" "${_ssh_zip}"
        printf "\n"
    else
        __copy_zip
    fi
    if __decrypt; then
        __done "ssh-raw"
    else
        echo "error decyrpt"
        false
    fi
}

get_d_setup() {
    __start "d_setup"

    local _link="shengdichen/d_setup.git"
    (
        cd || exit 3
        if ! (git clone "git@github.com:${_link}" dot >/dev/null); then
            __error "clone: ${_link} (bad internet?)"
        fi
        __done "d_setup"
    )
}

get_prv() {
    __start "d-prv"

    local _mountpt="${MOUNT_ROOT}/${MOUNT_MATRIX}"
    mkdir -p "${_mountpt}"

    __mount() {
        # source of prv
        local _ssh_profile="ssh_matrix_ext"
        (
            cd "${MOUNT_ROOT}" || exit 3
            while ! mount | grep "${_ssh_profile}" >/dev/null 2>&1; do
                if ! sshfs "${_ssh_profile}:/" "${MOUNT_MATRIX}" -o "reconnect,idmap=user"; then
                    printf "d-prv> mount [%s] failed, retrying" "${_ssh_profile}"
                    sleep 3
                fi
            done
        )
    }

    __clone() {
        local _repo="file://${_mountpt}/home/main/dot/dot/${DOT_PRV}"
        (
            cd "${DOT_ROOT}" || exit 3
            # specify |-b| to prevent warning for missing default brach name
            git clone -b main "${_repo}" "${DOT_PRV}"
        )
    }

    __setup() {
        # get ready for stowing(-override)
        rm -r "${HOME}/.ssh"

        (
            cd "${DOT_ROOT}/${DOT_PRV}" && ./"setup.sh"
        )
    }

    if ! __mount; then
        rmdir "${_mountpt}"
        __error "d-prv> mount"
    fi

    fusermount -u "${_mountpt}" && rmdir "${_mountpt}"
    if ! __clone; then
        __error "d-prv> clone"
    fi
    if ! __setup; then
        __error "d-prv> clone"
    fi
    __done "d-prv"
    unset -f __mount __clone __setup
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
