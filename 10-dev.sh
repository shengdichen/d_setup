source "./util.sh"

function python() {
    install "arch" \
        python python-pip python-pipx python-poetry \
        pycharm-community-edition \
        python-lsp-server python-lsp-black \
        python-black python-aiohttp \
        python-rope python-mccabe flake8 python-pylint \
        python-pyflakes

    pipx install --include-deps pylsp-rope

    # pycharm-config:
    # 1. install plugin
    #   dard-purple
    #   ideavim
    #   black-connect
    # 2. configure:
    #   a. visual:
    #       Settings->Appearance&Behavior->Appearance->Theme: dark purple
    #       Settings->Appearance&Behavior->Appearance->Use custom font: Avenir
    #       Settings->Editor->Font: Shevska
    #   b. blackd:
    #       Settings->Tools->BlackConnect:
    #           Detect Path for blackd
    # 3. bind:
    #   Settings->Keymap:
    #   Run->Run/Debug->Run: Alt-Shift-Enter
    # 4. restart pycharm
}

function langs() {
    install "arch" \
        lua-language-server \
        nodejs npm \
        ruby bash-language-server shellcheck \
        sqlite sqlite-doc sqlite-analyzer sqlitebrowser
}

function libs() {
    install "arch" \
        qt6-base qt6-wayland qt6-tools qt6-doc \
        qt5-base qt5-wayland qt5-tools qt5-doc \
        gtk4 gtk3

    npm install --global "sql-language-server" "vim-language-server"
}

function main() {
    python
    langs
    libs

    unset -f python langs libs
}
main
unset -f main
