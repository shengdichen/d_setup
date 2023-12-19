#!/usr/bin/env dash

__base() {
    "${SHELL}" "./00.sh"
    "${SHELL}" "./10-dev.sh"
    "${SHELL}" "./10-mail.sh"
    "${SHELL}" "./10-qutebrowser.sh"
}

__extra() {
    . "./20.sh"
    __office
    __media
    __game
}

main() {
    __base
    __extra

    unset -f __base __extra
}
main
unset -f main
