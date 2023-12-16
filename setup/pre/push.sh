push_to_xyz() {
    local \
        profile="ssh_xyz" \
        script_root="domains/shengdichen.xyz/public_html/install"

    ssh "${profile}" mkdir -p ${script_root}
    for f in "00.sh" "01.sh" "02.sh" "pacman.conf"; do
        scp \
            "./${f}" \
            "${profile}:${script_root}/."
    done

    echo "Done! Obtain with:"
    echo "\$ curl -LO shengdichen.xyz/install/0[1|2|3].sh"
}
push_to_xyz
unset -f push_to_xyz
