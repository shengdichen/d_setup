pacman -S --needed \
    sqlite \
    sqlite-doc sqlite-analyzer sqlitebrowser

function language_server() {
    npm install --global "sql-language-server"
}
