#!/usr/bin/env dash

. "./util.sh"

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

__python() {
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

__java() {
    install "arch" \
        jdk-openjdk openjdk-doc openjdk-src \
        jdk17-openjdk openjdk17-doc openjdk17-src \
        jdk11-openjdk openjdk11-doc openjdk11-src
}

__js() {
    install "arch" \
        nodejs npm typescript \
        typescript-language-server eslint_d

    install "npm" \
        prettier-standard standard ts-standard \
        @fsouza/prettierd \
        vscode-langservers-extracted
}

langs() {
    clone_and_stow -- d_dev
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

libs() {
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

main() {
    langs
    libs

    unset -f __python langs libs
}
main
unset -f main
