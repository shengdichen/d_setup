source "../util.sh"

function sync_time() {
    local date_pattern="Date: "
    "$(__sudo)" date -s "$(\
        curl -s --head http://google.com | \
        grep "^${date_pattern}" | \
        sed "s/${date_pattern}//g"\
    )"
    "$(__sudo)" hwclock -w --utc
}

function main() {
    sync_time
    unset -f sync_time
}
main
unset -f main
