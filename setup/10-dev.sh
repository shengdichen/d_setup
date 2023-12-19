source "./util.sh"

obesities() {
    # pycharm-config:
    # 1. plugin
    #       dark-purple
    #       ideavim
    #       black-connect
    # 2. configure
    #   a. visual:
    #       Settings->Appearance&Behavior->Appearance->Theme: dark purple
    #       Settings->Appearance&Behavior->Appearance->Use custom font: Avenir
    #       Settings->Editor->Font: Shevska
    #   b. blackd:
    #       Settings->Tools->BlackConnect:
    #           Detect Path for blackd
    # 3. keybind
    #   a. Settings->Keymap:
    #       Run->Run/Debug->Run: Alt-Shift-Enter
    # 4. restart pycharm

    install "aur" vscodium-insiders-bin

    install "arch" \
        pycharm-community-edition \
        intellij-idea-community-edition
    install "aur" android-studio
}

function __nvim() {
    local repo="d_nvim"
    clone_and_stow --sub -- self "${repo}"

    (
        cd "$(dot_dir)/${repo}/.config/nvim/conf/rpre/pack/start/start" || exit 3
        clone_and_stow --cd no --no-stow -- github "nvim-cmp" "hrsh7th"
        # cmp integration with neovim's (builtin) lsp
        clone_and_stow --cd no --no-stow -- github "cmp-nvim-lsp" "hrsh7th"

        clone_and_stow --cd no --no-stow -- github "LuaSnip" "L3MON4D3"
        # cmp integration with luasnip
        clone_and_stow --cd no --no-stow -- github "cmp_luasnip" "saadparwaiz1"
        # snippets collection
        clone_and_stow --cd no --no-stow -- github "friendly-snippets" "rafamadriz"

        clone_and_stow --cd no --no-stow -- github "plenary.nvim" "nvim-lua"
        clone_and_stow --cd no --no-stow -- github "none-ls.nvim" "nvimtools"

        clone_and_stow --cd no --no-stow -- github "gitsigns.nvim" "lewis6991"
        clone_and_stow --cd no --no-stow -- github "indent-blankline.nvim" "lukas-reineke"
        clone_and_stow --cd no --no-stow -- github "neodev.nvim" "folke"

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
        python python-pip python-pipx python-poetry

    install "arch" \
        python-lsp-server ruff-lsp \
        python-black python-aiohttp python-lsp-black \
        python-mccabe flake8 python-pylint python-pyflakes

    install "arch" python-rope
    install "aurhelper" python-pylsp-rope

    install "arch" python-isort
    install "aurhelper" python-lsp-isort

    install "arch" mypy
    install "aurhelper" python-lsp-mypy

    install "arch" python-ruff ruff-lsp
    install "aurhelper" python-lsp-ruff
}

function __java() {
    install "arch" \
        jdk-openjdk openjdk-doc openjdk-src \
        jdk17-openjdk openjdk17-doc openjdk17-src \
        jdk11-openjdk openjdk11-doc openjdk11-src
}

function __js() {
    install "arch" \
        nodejs npm typescript \
        typescript-language-server eslint_d

    install "npm" \
        prettier-standard standard ts-standard \
        @fsouza/prettierd \
        vscode-langservers-extracted
}

function langs() {
    clone_and_stow -- self d_dev
    __python
    __java
    __js

    install "arch" \
        dash checkbashisms \
        lua luajit luarocks lua-language-server \
        clang lld \
        rust \
        ghc cabal-install stack haskell-language-server \
        ruby

    install "arch" \
        bash-language-server shellcheck shfmt
    install "aurhelper" beautysh

    install "npm" \
        vim-language-server

    install "arch" \
        sqlite sqlite-doc sqlite-analyzer sqlitebrowser
    install "npm" \
        sql-language-server

    install "npm" alex write-good textlint
    install "aurhelper" proselint languagetool-rust
}

function libs() {
    install "arch" \
        qt6-base qt6-wayland qt6-tools qt6-doc \
        qt5-base qt5-wayland qt5-tools qt5-doc

    install "arch" \
        gtk4 gtk3

    install "arch" \
        traceroute mtr \
        openbsd-netcat nmap \
        whois
}

function main() {
    __nvim
    langs
    libs

    unset -f __nvim __python langs libs
}
main
unset -f main
