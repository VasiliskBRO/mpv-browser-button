#!/usr/bin/env bash
# Обработчик ссылок mpvpip://play?url=<адрес>&start=<секунды>&ref=<страница>&title=<название> (Linux).
# Их открывает кнопка «mpv» на видео в браузере; система запускает этот файл через mpvpip.desktop.
# Принимаются только ссылки http/https: чужой сайт не может передать mpv свои параметры.
set -u

MPV=mpv
ARGS=(--force-window=immediate)
# Свои настройки: ~/.config/mpv-browser-button/config (MPV=/путь/к/mpv, ARGS=(--ontop ...)).
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/mpv-browser-button/config"
[ -f "$CONFIG" ] && . "$CONFIG"

link="${1:-}"
query="${link#*\?}"
[ "$query" = "$link" ] && exit 0

# Раскодировать %XX и «+» из адреса.
urldecode() {
    local s="${1//+/ }"
    s="${s//\\/\\\\}"
    printf '%b' "${s//%/\\x}"
}

url='' start='' ref='' title=''
IFS='&' read -r -a pairs <<< "$query"
for pair in "${pairs[@]}"; do
    key="${pair%%=*}"
    value="$(urldecode "${pair#*=}")"
    case "$key" in
        url) url="$value" ;;
        start) start="$value" ;;
        ref) ref="$value" ;;
        title) title="$value" ;;
    esac
done

is_web() { [[ "$1" =~ ^https?:// ]]; }
is_web "$url" || exit 0

# Kodik (animelib и др.): плеер часто начинает с 360p, а на сервере есть лучше.
kodik='/[0-9]{3,4}\.mp4:hls:manifest\.m3u8'
if [[ "$url" =~ $kodik ]] && command -v curl >/dev/null; then
    for q in 1080 720 480; do
        candidate="$(sed -E "s#$kodik#/$q.mp4:hls:manifest.m3u8#" <<< "$url")"
        if curl -sfIL --max-time 4 -o /dev/null "$candidate"; then
            url="$candidate"
            break
        fi
    done
fi

args=("${ARGS[@]}")
if [[ "$start" =~ ^[0-9]+(\.[0-9]+)?$ ]] && [ "${start%%.*}" -gt 1 ]; then
    args+=("--start=$start")
fi
is_web "$ref" && args+=("--referrer=$ref")
title="${title:0:200}"
[ -n "$title" ] && args+=("--force-media-title=$title")

# Отвязываем mpv от браузера, чтобы он не закрылся вместе с ним.
if command -v setsid >/dev/null; then
    setsid -f "$MPV" "${args[@]}" -- "$url" >/dev/null 2>&1 < /dev/null
else
    nohup "$MPV" "${args[@]}" -- "$url" >/dev/null 2>&1 < /dev/null &
fi
