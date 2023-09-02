function __install_dict() {
    cd "/usr/share/qutebrowser/scripts/"
    python "dictcli.py" install \
        de-DE en-US es-ES fr-FR it-IT pt-BR ru-RU sv-SE

}

function main() {
    __install_dict

    unfunction __install_dict
}
main
unfunction main
