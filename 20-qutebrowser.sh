source "./util.sh"

function __install() {
    install "arch" \
        "qutebrowser" "tor"
    clone_and_stow self d_qutebrowser

    systemctl enable --now "tor.service"
}

function __install_dict() {
    (\
        cd "/usr/share/qutebrowser/scripts/" && \
        python "dictcli.py" install \
            "de-DE" "en-US" "es-ES" "fr-FR" "it-IT" "pt-BR" "ru-RU" "sv-SE"\
    )
}

function main() {
    __install
    __install_dict

    unfunction __install __install_dict
}
main
unfunction main
