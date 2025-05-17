#!/usr/bin/env dash

. "../util.sh"

__libs() {
    __install arch "${@}" -- \
        qt6-base qt6-wayland qt6-tools qt6-doc \
        qt5-base qt5-wayland qt5-tools qt5-doc

    __install arch "${@}" -- \
        glib2-devel gtk4 gtk3
}

__lang_main() {
    __base() {
        __install arch "${@}" -- \
            lua luajit luarocks lua-language-server

        __install arch "${@}" -- \
            dash checkbashisms \
            bash-language-server shellcheck shfmt
        __install aurhelper "${@}" -- beautysh

        __install arch "${@}" -- clang lld rust
    }

    __python() {
        __install arch "${@}" -- \
            python python-pip python-pipx python-poetry

        __install arch "${@}" -- pyright

        __install arch "${@}" -- \
            python-lsp-server ruff-lsp \
            python-black python-aiohttp python-lsp-black \
            python-mccabe flake8 python-pylint python-pyflakes

        __install arch "${@}" -- python-rope
        __install aurhelper "${@}" -- python-pylsp-rope

        __install arch "${@}" -- python-isort
        __install aurhelper "${@}" -- python-lsp-isort

        __install arch "${@}" -- mypy
        __install aurhelper "${@}" -- python-lsp-mypy

        __install arch "${@}" -- python-ruff ruff-lsp
        __install aurhelper "${@}" -- python-lsp-ruff
    }

    __js() {
        __install arch "${@}" -- \
            nodejs npm typescript \
            typescript-language-server
        __install aurhelper "${@}" -- vscode-langservers-extracted
        __install arch "${@}" -- \
            eslint prettier
        __install npm -- \
            standard ts-standard
    }

    __prose() {
        __install npm -- \
            textlint \
            textlint-rule-write-good \
            textlint-rule-alex \
            textlint-rule-max-number-of-lines \
            textlint-rule-date-weekday-mismatch \
            textlint-rule-doubled-spaces \
            textlint-rule-no-zero-width-spaces \
            textlint-plugin-html \
            textlint-plugin-latex2e
        __install npm -- alex write-good
        __install aurhelper "${@}" -- proselint ltex-ls-bin
    }

    __base "${@}"
    __python "${@}"
    __js "${@}"
    __prose "${@}"
    unset -f __base __python __js __prose
}

__lang_misc() {
    __install arch "${@}" -- \
        ghc cabal-install stack haskell-language-server

    __install arch "${@}" -- \
        zig zls

    __install arch "${@}" -- ruby

    __install arch "${@}" -- \
        dotnet-runtime dotnet-sdk aspnet-runtime
    __install aurhelper "${@}" -- omnisharp-roslyn-bin
    __install dotnet "${@}" -- csharpier

    __install arch "${@}" -- \
        jdk-openjdk openjdk-doc openjdk-src \
        jdk17-openjdk openjdk17-doc openjdk17-src \
        jdk11-openjdk openjdk11-doc openjdk11-src \
        maven gradle
    __install aurhelper "${@}" -- jdtls

    __install npm -- vim-language-server

    __install arch "${@}" -- \
        sqlite sqlite-doc sqlite-analyzer sqlitebrowser
    __install npm -- sql-language-server
}

__obesities() {
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

    __install aur -- vscodium-insiders-bin

    __install arch "${@}" -- \
        pycharm-community-edition \
        intellij-idea-community-edition
    __install aur -- android-studio

    __install arch "${@}" -- jupyterlab
}

main() {
    local _level="0"
    case "${1}" in
        "0" | "1" | "2")
            _level="${1}"
            shift
            ;;
    esac

    if [ "${_level}" -ge 0 ]; then
        dotfile -- d_dev
        __libs "${@}"
        __lang_main "${@}"
        if [ "${_level}" -ge 1 ]; then
            __lang_misc "${@}"
            if [ "${_level}" -ge 2 ]; then
                __obesities "${@}"
            fi
        fi
    fi
    unset -f __libs __lang_main __lang_misc __obesities
}
main "${@}"
unset -f main
