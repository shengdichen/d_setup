source "./util.sh"

function __install() {
    install "arch" \
        "qutebrowser" "tor"
    clone_and_stow -- self d_qutebrowser
}

function __extra() {
    service_start -- tor

    # download (offline) dictionaries
    (
        local _dict_dir="${HOME}/.local/share/qutebrowser/qtwebengine_dictionaries"
        mkdir -p "${_dict_dir}"
        cd "${_dict_dir}" || exit 3

        for l in "de-DE" "en-US" "es-ES" "fr-FR" "it-IT" "pt-BR" "ru-RU" "sv-SE"; do
            if ! find . -maxdepth 1 -printf "%P\n" | grep -q "^${l}-.*\.bdic$"; then
                echo "[qutebrowser-dict:${l}] Installing"
                python "/usr/share/qutebrowser/scripts/dictcli.py" install "${l}"
            fi
        done
    )
}

function main() {
    __install
    __extra

    unset -f __install __extra
}
main
unset -f main
