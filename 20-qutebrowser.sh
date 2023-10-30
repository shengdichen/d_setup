source "./util.sh"

function __install() {
    install "arch" \
        "qutebrowser" "tor"
    clone_and_stow self d_qutebrowser
}

function __extra() {
    systemctl enable --now "tor.service"

    # download (offline) dictionaries
    python "/usr/share/qutebrowser/scripts/dictcli.py" install \
        "de-DE" "en-US" "es-ES" "fr-FR" "it-IT" "pt-BR" "ru-RU" "sv-SE"
}

function main() {
    __install
    __extra

    unfunction __install __extra
}
main
unfunction main
