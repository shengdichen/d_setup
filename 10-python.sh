pacman -S --needed \
    python python-pip python-pipx \
    python-black pycharm-community-edition

# // run as user, NOT root!
# $ pipx install "black[d]"

# pycharm-config:
#   1. theme (dark purple), ui-font: avenir; editor-font: source-code-pro
#   2. plugin: ideavim, black
#       a. detect blackd location
#   3. bind: Settings->Keymap
#       a. Alt-Shift-Enter
#       -> Run/Run/Debug/<logo>Run
