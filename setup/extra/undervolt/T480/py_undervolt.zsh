cmd="/home/main/.local/bin/undervolt"

function __set_temp() {
    "${cmd}" \
        --temp "$1"
}

function __set_cpu() {
    val="$1"

    "${cmd}" \
        --core -"${val}" \
        --cache -"${val}" \
}

function __set_gpu() {
    "${cmd}" \
        --gpu -"$1" \
        --uncore -"$1"

}

function __set_misc() {
    "${cmd}" \
        --analogio -"$1"
}

function __set_powerlimit_short() {
    "${cmd}" \
        --power-limit-short "$1" "$2"
}

function __set_powerlimit_long() {
    "${cmd}" \
        --power-limit-long "$1" "$2"
}

function __query() {
    "${cmd}" \
        --read
}

function __set() {
    __set_temp 95
    __set_cpu 93
    __set_gpu 73
    __set_misc 7
    __set_powerlimit_short 44 0.003
    __set_powerlimit_long 44 13
    __query
}

function __unset() {
    __set_temp 0
    __set_cpu 0
    __set_gpu 0
    __set_misc 0
    __set_powerlimit_short 31 0.003
    __set_powerlimit_long 23 13
    __query
}

function main() {
    __set

    unset cmd
    unfunction \
        __set_temp __set_cpu __set_gpu __set_misc \
        __set_powerlimit_short __set_powerlimit_long \
        __set __unset \
        __query
}
main
unfunction main
