source "./util.sh"

function __nvim() {
    local repo="d_nvim"
    clone_and_stow --sub -- self "${repo}"

    (
    cd "$(dot_dir)/${repo}/.config/nvim/conf/rpre/pack/start/start" || exit 3
    clone_and_stow --cd no --no-stow -- github "nvim-cmp" "hrsh7th"
    clone_and_stow --cd no --no-stow -- github "cmp-nvim-lsp" "hrsh7th"
    clone_and_stow --cd no --no-stow -- github "LuaSnip" "L3MON4D3"
    clone_and_stow --cd no --no-stow -- github "cmp_luasnip" "saadparwaiz1"

    # REF:
    #   https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md#transformations
    cd "./LuaSnip" || exit 3
    if [[ ! -e "./lua/luasnip-jsregexp.so" ]]; then
        make install_jsregexp
    fi
    )
}

function __python() {
    install "arch" \
        python python-pip python-pipx python-poetry \
        pycharm-community-edition

    install "arch" \
        python-black python-aiohttp python-lsp-server python-lsp-black \
        python-rope python-mccabe flake8 python-pylint python-pyflakes

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
    clone_and_stow -- self d_ideavim
    __python

    install "arch" \
        lua luajit luarocks lua-language-server \
        clang lld \
        ghc cabal-install stack haskell-language-server

    install "arch" \
        bash-language-server shellcheck \
        nodejs npm ruby
    npm install --global "vim-language-server"

    install "arch" \
        sqlite sqlite-doc sqlite-analyzer sqlitebrowser
    npm install --global "sql-language-server"
}

function libs() {
    install "arch" \
        qt6-base qt6-wayland qt6-tools qt6-doc \
        qt5-base qt5-wayland qt5-tools qt5-doc \

    install "arch" \
        gtk4 gtk3
}

function main() {
    __nvim
    langs
    libs

    unset -f __nvim __python langs libs
}
main
unset -f main
