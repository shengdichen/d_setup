#!/usr/bin/env dash

. "../util.sh"

__base() {
    __install aurhelper -- python-validity
    service_start -- python3-validity
}

__record() {
    local _finger
    for _side in "left" "right"; do
        for _detail in "index" "little"; do
            _finger="${_side}-${_detail}-finger"
            if ! fprintd-list "${USER}" | grep -q "${_finger}$"; then
                if __yes_or_no "record> [${_finger}]"; then
                    fprintd-enroll -f "${_finger}"
                fi
            else
                if __yes_or_no "re-record> [${_finger}]"; then
                    fprintd-enroll -f "${_finger}"
                fi
            fi
        done
    done
}

__config() {
    local _pam_path="/etc/pam.d/"
    local _allow_passwd="auth sufficient pam_unix.so try_first_pass likeauth nullok"
    local _use_fingerprint="auth sufficient pam_fprintd.so"

    __config_one() {
        local _passwd=""
        if [ "${1}" = "passwd" ]; then
            _passwd="yes"
            shift
        fi
        if [ "${1}" = "--" ]; then shift; fi

        local _target="${_pam_path}/${1}" _sed_cmd="/^auth\s\+/i"
        printf "config> [%s]\n" "${_target}"
        if ! sudo grep -q "pam_fprintd" "${_target}"; then
            if [ "${_passwd}" ]; then
                _sed_cmd="${_sed_cmd} ${_allow_passwd}\n${_use_fingerprint}\n"
            else
                _sed_cmd="${_sed_cmd} ${_use_fingerprint}\n"
            fi
            sudo sed -i "${_sed_cmd}" "${_target}"
        fi
    }

    __config_one -- "system-local-login"
    __config_one -- "sudo"
    __config_one passwd -- "swaylock"

    unset -f __config_one
}

__base
__record
__config
unset -f __base __record __config
