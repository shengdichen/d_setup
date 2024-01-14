#!/usr/bin/env dash

. "../util.sh"

sync_time() {
    local date_pattern="Date: "
    "$(__sudo)" date -s "$(
        curl -s --head http://google.com |
            grep "^${date_pattern}" |
            sed "s/${date_pattern}//g"
    )" 1>/dev/null
    "$(__sudo)" hwclock -w --utc
}

main() {
    sync_time
    unset -f sync_time
}
main
unset -f main
