#!/usr/bin/env dash

main() {
    "./base.sh" "${@}"
    "./dev.sh" "${@}"
    "./goof.sh" "${@}"
}
main "${@}"
unset -f main
