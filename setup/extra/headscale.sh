#!/usr/bin/env dash

SERVER_LOCAL="https://192.168.1.6:8080"
SERVER_REMOTE="https://home.shengdichen.xyz:8088"

__server() {
    __f() {
        if [ "${1}" = "-i" ]; then
            docker exec -it C-headscale headscale "${@}"
            return
        fi
        docker exec C-headscale headscale "${@}"
    }

    __user() {
        case "${1}" in
            "add")
                shift
                __f users create "${1}"
                ;;
            "delete")
                shift
                __f users destroy "${1}"
                ;;
            *)
                __f users list
                ;;
        esac
    }

    __node_ls() {
        __f nodes list
    }

    __node_add() {
        local _user="shc" _key
        while [ "${#}" -gt 0 ]; do
            case "${1}" in
                "--user")
                    _user="${2}"
                    shift 2
                    ;;
                "--key")
                    _key="${2}"
                    shift 2
                    ;;
            esac
        done

        if [ ! "${_key}" ]; then
            printf "node/add> key: "
            read -r _key
            printf "\n"
        fi

        printf "node/ls> \n"
        __node_ls

        printf "node/add> user [%s]; key [%s]\n" "${_user}" "${_key}"
        __f nodes register \
            --user "${_user}" \
            --key mkey:"${_key}"

        printf "node/ls> \n"
        __node_ls
    }

    __node_delete() {
        __f nodes list

        local _line _node
        __f nodes list | tail -n "+2" | fzf --multi --ansi | while read -r _line; do
            _node="$(printf "%s" "${_line}" | cut -d " " -f "1")"
            printf "server/node: handling node [%s]..." "${_node}"
            __f nodes delete --force -i "${_node}" # --force to bypass confirmation
            printf "; done!\n"
        done
        printf "\n"

        __f nodes list
    }

    __node_rename() {
        __f nodes list

        local _node
        printf "server/node> id of node to rename: "
        read -r _node

        local _name
        printf "server/node> (new) name of node [%s]: " "${_node}"
        read -r _name

        printf "\n"
        __f nodes rename "${_name}" -i "${_node}"

        __f nodes list
    }

    __route() {
        __list() {
            __f routes list
        }

        local _mode="${1}"

        if [ ! "${_mode}" ]; then
            __list
            return
        fi

        __filter() {
            case "${_mode}" in
                "exitnode")
                    __list | grep -e "::/0" -e "0.0.0.0/0"
                    ;;
                "subnet")
                    __list |
                        tail -n "+2" | # filter away the (first) header-line
                        grep -v -e "::/0" -e "0.0.0.0/0"
                    ;;
                *)
                    printf "server/route> huh? which mode?\n"
                    exit 3
                    ;;
            esac
        }

        __list | head -n "+1" # print header-line for visual clue
        __filter
        printf "\n"

        local _operator="${2}"
        if [ ! "${_operator}" ]; then
            printf "server/%s> mode: [o]n; o[f]f; [d]elete " "${_mode}" && read -r _operator
            case "${_operator}" in
                "o" | "O")
                    _operator="enable"
                    ;;
                "f" | "F")
                    _operator="disable"
                    ;;
                "d" | "D")
                    _operator="delete"
                    ;;
                *)
                    printf "server/route> huh? which operator?\n"
                    exit 3
                    ;;
            esac
        fi

        printf "server/%s> to %s: " "${_mode}" "${_operator}"
        printf "\n\n"
        local _route
        __filter | fzf --multi --ansi | while read -r _line; do
            _route="$(printf "%s" "${_line}" | cut -d " " -f "1")"
            printf "server/%s> handling route [%s]..." "${_mode}" "${_route}"
            __f routes "${_operator}" --route "${_route}"
            printf "; done!\n"
        done
        printf "\n"

        __filter
    }

    __authkey_make() {
        __f preauthkeys create --user shc
    }

    case "${1}" in
        "user")
            shift
            __user "${@}"
            ;;
        "node")
            __node_ls
            ;;
        "node-add")
            shift
            __node_add "${@}"
            ;;
        "node-delete")
            __node_delete
            ;;
        "node-rename")
            __node_rename
            ;;
        "route")
            __route
            ;;
        "subnet")
            shift
            __route subnet "${@}"
            ;;
        "exitnode")
            shift
            __route exitnode "${2}"
            ;;
    esac

}

__client() {
    __setup() {
        sudo pacman -S --needed --noconfirm -- tailscale
        sudo systemctl start -- tailscaled.service
    }

    __on() {
        sudo systemctl start -- tailscaled.service
        sudo tailscale up
        tailscale status
    }

    __off() {
        sudo tailscale down
        sudo systemctl stop -- tailscaled.service
        printf "client/off> done! \n"
    }

    __node_make_exit_node() {
        sudo tailscale set --advertise-exit-node
    }

    __register_node() {
        local _server="${SERVER_REMOTE}"
        local _use_subnet="" _as_exit_node="" _accept_routes=""
        while [ "${#}" -gt 0 ]; do
            case "${1}" in
                "--server")
                    _server="${2}"
                    shift 2
                    ;;
                "--use-subnet")
                    _use_subnet="yes"
                    shift
                    ;;
                "--as-exit-node")
                    _as_exit_node="yes"
                    shift
                    ;;
                "--accept-routes")
                    _accept_routes="yes"
                    shift
                    ;;
            esac
        done

        local _cmd="sudo tailscale up "

        if [ "${_server}" ]; then
            _cmd="${_cmd} --login-server ${_server}"
        fi
        if [ "${_use_subnet}" ]; then
            _cmd="${_cmd} --advertise-routes 192.168.1.0/24"
        fi
        if [ "${_as_exit_node}" ]; then
            _cmd="${_cmd} --advertise-exit-node"
        fi
        if [ "${_accept_routes}" ]; then
            _cmd="${_cmd} --accept-routes"
        fi

        eval "${_cmd}" --force-reauth
    }

    __register_node_station() {
        __register_node --use-subnet
        __server subnet
    }

    __register_node_mobile() {
        __register_node --accept-routes
    }

    case "${1}" in
        "on")
            __on
            ;;
        "off")
            __off
            ;;
        "register-station")
            __register_node_station
            ;;
        "register-mobile")
            __register_node_mobile
            ;;
    esac

}

case "${1}" in
    "server")
        shift
        __server "${@}"
        ;;
    "client")
        shift
        __client "${@}"
        ;;
esac
