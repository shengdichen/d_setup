function __base() {
    "${SHELL}" "./00-sys.sh"
    "${SHELL}" "./10-dev.sh"
    "${SHELL}" "./20-mail.sh"
    "${SHELL}" "./20-qutebrowser.sh"
}

function __extra() {
    source "./20-graphic.sh"
    __office
    __media
    __game
}

function main() {
    __base
    __extra

    unset -f __base __extra
}
main
unset -f main
