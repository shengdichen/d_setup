source "./util.sh"

function __install() {
    install "arch" \
        "qutebrowser" "tor"

    systemctl enable --now "tor.service"
}

function __install_dict() {
    (\
        cd "/usr/share/qutebrowser/scripts/" && \
        python "dictcli.py" install \
            "de-DE" "en-US" "es-ES" "fr-FR" "it-IT" "pt-BR" "ru-RU" "sv-SE"\
    )
}

function __dot() {
    (cd "$(dot_dir)" && clone_and_stow self d_qutebrowser)
}

function main() {
    __install
    __install_dict
    __dot

    unfunction __install __install_dict __dot
}
main
unfunction main
