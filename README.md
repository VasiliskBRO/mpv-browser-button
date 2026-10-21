# mpv browser button

Кнопка «⏵ mpv» на любом видео в браузере: открывает ролик в [mpv](https://mpv.io) **с того же места**, а в браузере ставит его на паузу. Вместо встроенного «картинка в картинке» — полноценный плеер со своими настройками, горячими клавишами и окном, которым управляешь как хочешь.

- YouTube, Twitch, VK, Rutube и другие — через yt-dlp, в лучшем качестве.
- Сайты, которых yt-dlp не знает (например, плееры Kodik на аниме-сайтах), — по прямой ссылке на поток; у Kodik качество само поднимается до лучшего.
- Название ролика попадает в заголовок mpv, даже если плеер встроен в чужое окошко.
- Работает в Firefox, Chrome, Edge — везде, где есть Violentmonkey или Tampermonkey. Только Windows.

Хорошо дружит с оболочкой [Prism](https://github.com/VasiliskBRO/mpv-prism), но нужен только сам mpv.

## Установка

Нужны: Windows 10/11, [mpv](https://mpv.io/installation/) и [yt-dlp](https://github.com/yt-dlp/yt-dlp) (`winget install yt-dlp`).

1. Скачай репозиторий (Code → Download ZIP) и распакуй.
2. Правой кнопкой по `install.ps1` → **«Выполнить с помощью PowerShell»**. Он найдёт mpv (если нет — спросит путь) и научит Windows открывать ссылки `mpvpip://`.
3. Поставь в браузер **Violentmonkey** ([Firefox](https://addons.mozilla.org/firefox/addon/violentmonkey/) · [Chrome/Edge](https://chromewebstore.google.com/detail/violentmonkey/jinjaccalgkegednnccohejagnlnfdag)).
4. Открой **[mpv-button.user.js](https://raw.githubusercontent.com/VasiliskBRO/mpv-browser-button/master/mpv-button.user.js)** → «Установить». Дальше скрипт обновляется сам.
5. Наведи мышь на видео → «⏵ mpv». В первый раз браузер спросит, можно ли открыть ссылку `mpvpip` — поставь «Всегда».

## Настройки

- **Где кнопка** (по центру / справа / слева сверху): значок Violentmonkey → «Кнопка mpv: … (сменить)».
- **Выключить на сайте**: значок Violentmonkey → снять галочку у скрипта для этого сайта.
- **Параметры mpv**: `%LOCALAPPDATA%\mpv-browser-button\config.json`, список `args` (например, `"--ontop"`). Переустановка их сохраняет.
- **Другой mpv**: `install.ps1 -Mpv "D:\mpv\mpv.exe"`.

## Удаление

`uninstall.ps1` убирает обработчик и запись в реестре; скрипт удаляется в панели Violentmonkey.

## Как это устроено

Кнопка собирает адрес (страницу для yt-dlp или прямой поток), секунду и название, ставит видео на паузу и открывает ссылку `mpvpip://play?url=…&start=…`. Windows отдаёт её `mpvpip.ps1` — он запускается невидимо, принимает только `http/https` и запускает mpv. Никаких серверов и расширений с доступом к системе.

**Реклама:** у некоторых плееров (Kodik) реклама играет в том же видео — если нажать кнопку во время неё, в mpv уйдёт реклама. Блокировщик (uBlock Origin) это решает.

---

**English.** A userscript + tiny Windows URL handler: hover any video, click “mpv”, and it continues in mpv from the same second (paused in the browser). Run `install.ps1`, install Violentmonkey, open the `.user.js` link above. Needs mpv and yt-dlp. MIT license.
