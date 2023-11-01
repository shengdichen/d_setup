source "../util.sh"

function set_bat() {
    for bat in $(find "/sys/class/power_supply/" -maxdepth 1 -printf "%P\n" | grep "^BAT"); do
        "$(__sudo)" tlp setcharge 59 60 "${bat}"
    done
}
set_bat
