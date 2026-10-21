#!/usr/bin/env bash
# Установка (Linux, бета): кладёт обработчик в ~/.local/share/mpv-browser-button
# и регистрирует ссылки mpvpip:// через mpvpip.desktop (только для текущего пользователя).
# Запуск: bash install.sh
set -eu

here="$(cd "$(dirname "$0")" && pwd)"
data="${XDG_DATA_HOME:-$HOME/.local/share}"
dest="$data/mpv-browser-button"
apps="$data/applications"

command -v mpv >/dev/null || echo "Внимание: mpv не найден в PATH. Поставь его или укажи MPV=/путь в ~/.config/mpv-browser-button/config"
command -v yt-dlp >/dev/null || echo "Внимание: yt-dlp не найден — YouTube, Twitch и т.п. не откроются."
command -v xdg-mime >/dev/null || { echo "Нужен xdg-mime (пакет xdg-utils)."; exit 1; }

mkdir -p "$dest" "$apps"
install -m 755 "$here/mpvpip.sh" "$dest/mpvpip.sh"

cat > "$apps/mpvpip.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=mpv browser button
Comment=Opens mpvpip:// links from the browser button in mpv
Exec="$dest/mpvpip.sh" %u
NoDisplay=true
Terminal=false
MimeType=x-scheme-handler/mpvpip;
EOF

xdg-mime default mpvpip.desktop x-scheme-handler/mpvpip
command -v update-desktop-database >/dev/null && update-desktop-database "$apps" >/dev/null 2>&1 || true

echo
echo "Готово. Осталось в браузере:"
echo "  1. Поставить расширение Violentmonkey (или Tampermonkey)."
echo "  2. Открыть ссылку на скрипт из README и нажать «Установить»."
echo "  3. При первом нажатии кнопки разрешить браузеру открывать ссылки mpvpip («Всегда»)."
