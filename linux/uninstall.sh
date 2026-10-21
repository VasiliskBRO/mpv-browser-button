#!/usr/bin/env bash
# Удаление (Linux): убирает обработчик и mpvpip.desktop.
# Сам скрипт кнопки удаляется в Violentmonkey (значок → панель управления → корзина).
set -u

data="${XDG_DATA_HOME:-$HOME/.local/share}"
rm -rf "$data/mpv-browser-button"
rm -f "$data/applications/mpvpip.desktop"
command -v update-desktop-database >/dev/null && update-desktop-database "$data/applications" >/dev/null 2>&1
echo "Удалено. Не забудь удалить скрипт кнопки в Violentmonkey."
