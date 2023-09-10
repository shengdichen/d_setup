pacman -S --needed \
    python python-pip python-pipx python-poetry \
    pycharm-community-edition

pacman -S --needed \
    python-lsp-server \
    python-rope python-pyflakes python-mccabe yapf python-whatthepatch

# // run as user, NOT root!
# $ pipx install "black[d]"

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
