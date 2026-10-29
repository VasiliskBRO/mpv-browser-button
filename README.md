# mpv browser button

Кнопка «⏵ mpv» на любом видео в браузере: открывает ролик в [mpv](https://mpv.io) **с того же места**, а в браузере ставит его на паузу. Вместо встроенного «картинка в картинке» — полноценный плеер со своими настройками, горячими клавишами и окном, которым управляешь как хочешь.

- YouTube, Twitch, VK, Rutube и другие — через yt-dlp, в лучшем качестве.
- Эфиры GoodGame — по адресу канала, всегда с текущего момента (в [Prism](https://github.com/VasiliskBRO/mpv-prism) их открывает streamlink).
- Сайты, которых yt-dlp не знает (например, плееры Kodik на аниме-сайтах), — по прямой ссылке на поток; у Kodik качество само поднимается до лучшего.
- AnimeLIB, свой плеер сайта (виден после входа): в mpv уходят плейлистом все серии той же озвучки, старт — с открытой серии и с той же секунды. Открывается лучшее качество; с оболочкой [Prism](https://github.com/VasiliskBRO/mpv-prism) его можно сменить прямо в mpv (`Alt+Q`), как на YouTube. Windows; Linux-версия пока открывает одну серию.
- Название ролика попадает в заголовок mpv, даже если плеер встроен в чужое окошко.
- Работает в Firefox, Chrome, Edge — везде, где есть Violentmonkey или Tampermonkey.
- **Windows** — проверено. **Linux** — бета (написано и проверено по частям, на живом Linux с браузером ещё не гоняли — отпишитесь в Issues, как у вас). macOS пока нет.

Хорошо дружит с оболочкой [Prism](https://github.com/VasiliskBRO/mpv-prism), но нужен только сам mpv.

## Установка

Нужны: Windows 10/11, [mpv](https://mpv.io/installation/) и [yt-dlp](https://github.com/yt-dlp/yt-dlp) (`winget install yt-dlp`).

1. Скачай репозиторий (Code → Download ZIP) и распакуй.
2. Правой кнопкой по `install.ps1` → **«Выполнить с помощью PowerShell»**. Он найдёт mpv (если нет — спросит путь) и научит Windows открывать ссылки `mpvpip://`.
3. Поставь в браузер **Violentmonkey** ([Firefox](https://addons.mozilla.org/firefox/addon/violentmonkey/) · [Chrome/Edge](https://chromewebstore.google.com/detail/violentmonkey/jinjaccalgkegednnccohejagnlnfdag)).
4. Открой **[mpv-button.user.js](https://raw.githubusercontent.com/VasiliskBRO/mpv-browser-button/master/mpv-button.user.js)** → «Установить». Дальше скрипт обновляется сам, а обработчик — нет: после обновления репо запусти `install.ps1` ещё раз (нужно для очереди серий AnimeLIB).
5. Наведи мышь на видео → «⏵ mpv». В первый раз браузер спросит, можно ли открыть ссылку `mpvpip` — поставь «Всегда».

### Linux (бета)

Нужны `mpv`, `yt-dlp`, `xdg-utils`, для Kodik — `curl` (всё есть в репозиториях дистрибутивов).

1. `git clone https://github.com/VasiliskBRO/mpv-browser-button && bash mpv-browser-button/linux/install.sh` — кладёт обработчик в `~/.local/share/mpv-browser-button` и регистрирует ссылки `mpvpip://` через `mpvpip.desktop`.
2. Дальше — шаги 3–5 выше (Violentmonkey, скрипт, «Всегда»).

Firefox/Chromium из Flatpak или Snap открывают такие ссылки через системный портал — обычно работает, но если кнопка молчит, это первое, что стоит проверить.

## Настройки

- **Где кнопка** (по центру / справа / слева сверху): значок Violentmonkey → «Кнопка mpv: … (сменить)».
- **Выключить на сайте**: значок Violentmonkey → снять галочку у скрипта для этого сайта.
- **Параметры mpv**: `%LOCALAPPDATA%\mpv-browser-button\config.json`, список `args` (например, `"--ontop"`). Переустановка их сохраняет.
- **Другой mpv**: `install.ps1 -Mpv "D:\mpv\mpv.exe"`.
- **Linux**: файл `~/.config/mpv-browser-button/config`, например `MPV=/usr/bin/mpv` и `ARGS=(--force-window=immediate --ontop)`.

## Удаление

`uninstall.ps1` (на Linux — `linux/uninstall.sh`) убирает обработчик и регистрацию ссылок; скрипт удаляется в панели Violentmonkey.

## Как это устроено

Кнопка собирает адрес (страницу для yt-dlp или прямой поток), секунду и название, ставит видео на паузу и открывает ссылку `mpvpip://play?url=…&start=…`. Система отдаёт её обработчику (`mpvpip.ps1` на Windows, `linux/mpvpip.sh` на Linux) — он запускается невидимо, принимает только `http/https` и запускает mpv. Никаких серверов и расширений с доступом к системе.

**Реклама:** у некоторых плееров (Kodik) реклама играет в том же видео — если нажать кнопку во время неё, в mpv уйдёт реклама. Блокировщик (uBlock Origin) это решает.

---

**English.** A userscript + tiny URL handler: hover any video, click “mpv”, and it continues in mpv from the same second (paused in the browser). Windows: run `install.ps1`. Linux (beta): `bash linux/install.sh` (needs xdg-utils). Then install Violentmonkey and open the `.user.js` link above. Needs mpv and yt-dlp. MIT license.
