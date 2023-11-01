function create_user() {
    if (( EUID != 0 )); then
        echo "Not root, exiting"
        exit 3
    fi

    pacman -S zsh zsh-completions zsh-syntax-highlighting

    local _me="shc"
    useradd -m -d /home/main -G wheel -s /bin/zsh "${_me}"
    groupmod -n god "${_me}"
    passwd "${_me}"

    visudo

    # TODO: switch to shc
    for d in ".local/share/" ".config/" ".cache/"; do
        mkdir -p "${HOME}/${d}"
    done
}

function get_ssh_config_raw() {
    local _mnt="/mnt" _ssh_dir="${HOME}/.ssh"
    sudo mount "$(find /dev -maxdepth 1 | fzf)" "${_mnt}"

    mkdir -p "${_ssh_dir}"
    # TODO: get the file names
    cp "${_mnt}/priv_key" "${_mnt}/priv_key" "${_ssh_dir}/."
    exit
}

function setup() {
    git clone git@github.com:shengdichen/d_setup.git "${HOME}/dot"
    local _ptr=
    sshfs \
    "ssh_syngy_ext:${3}" \
    "$(realpath "${4}")" \
    -o "reconnect,idmap=user"
}

function get_prv() {
    (
    cd "${HOME}/dot/dot" || exit 3
    stow -R --target="${HOME}" --ignore="\.git.*" --ignore="script" "d_prv"
    )
}
get_prv
