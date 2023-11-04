pacman -S --needed \
    s-tui throttled msr-tools

systemctl enable throttled
systemctl start throttled

pipx install undervolt
