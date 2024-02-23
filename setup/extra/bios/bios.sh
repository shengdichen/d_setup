#!/usr/bin/env dash

. "../../util.sh"

BIOS_BAK="bios_bak.bin"
BIOS_CURR="bios_curr.bin"

__set_bios_splash() {
    # REF:
    # https://www.reddit.com/r/thinkpad/comments/a57xhc/guide_custom_boot_logo_on_a_t480/

    local _bios="bios.img"
    __install aurhelper -- geteltorito
    geteltorito -o "${_bios}" n24ur09w.iso

    sudo dd if="${_bios}" of=/dev/sdX bs=4M
}

__flashrom() {
    case "${1}" in
        "read")
            shift
            "$(__sudo)" flashrom -p ch341a_spi -r "${1}"
            ;;
        "write")
            shift
            "$(__sudo)" flashrom -p ch341a_spi -w "${1}"
            ;;
        *)
            exit 3
            ;;
    esac
}

__backup() {
    local _bios_1="bios1.bin" _bios_2="bios2.bin"

    while true; do
        if ! (__flashrom read "${_bios_1}" && __flashrom read "${_bios_2}"); then
            printf "\n\n"
            printf "backup> reseat programmer maybe?"
            printf "\n\n"
            exit 3
        fi

        if diff "${_bios_1}" "${_bios_2}"; then
            mv "${_bios_1}" "${BIOS_CURR}"
            cp "${BIOS_CURR}" "${BIOS_BAK}"
            rm -f "${_bios_2}"
            printf "\n"
            printf "backup> DONE [proceed to subsequent flashing now]\n"
            printf "\n"
            break
        else
            printf "backup> bios-reads differ, retrying\n\n"
        fi
    done
}

__enable_menu_advanced() {
    local _patchfile="./patchfile" _out="./bios_with_advanced.bin"

    ./"UEFIPatch" "${BIOS_CURR}" "${_patchfile}" -o "${_out}"

    # from: "4C 4E 56 42   42 53 45 43   FB"
    # to:   "4C 4E 56 42   42 53 45 43   FF"
    okteta "${_out}"

    if __yes_or_no "flash> advanced"; then
        __flashrom write "${_out}"
    fi
}

__remove_intel_m_engine() {
    # before := 11 partition; HAP not set (success on t480)
    # opt_s := 11 partition; HAP set (success on t480)
    # opt_none := 1 partition; HAP not set (fail on t480)
    # opt_S := 1 partition; HAP set (fail on t480)

    local _out="bios_no_intel_me.bin"
    case "${1}" in
        "opt_s")
            python me_cleaner.py -s -O "${_out}" "${BIOS_CURR}"
            ;;
        "opt_none")
            python me_cleaner.py -O "${_out}" "${BIOS_CURR}"
            ;;
        "opt_S")
            python me_cleaner.py -S -O "${_out}" "${BIOS_CURR}"
            ;;
        *)
            printf "intel-me> huh?\n"
            ;;
    esac

    if __yes_or_no "flash> intel-me"; then
        __flashrom write "${_out}"
    fi
}

case "${1}" in
    "backup")
        __backup
        ;;
    *)
        exit 3
        ;;
esac
