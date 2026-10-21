# Обработчик ссылок mpvpip://play?url=<адрес>&start=<секунды>&ref=<страница>&title=<название>
# Их открывает кнопка «mpv» на видео в браузере. Windows запускает этот файл невидимо (conhost --headless).
# Принимаются только ссылки http/https: чужой сайт не может передать mpv свои параметры.
param([string]$Link)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Web

$config = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'config.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$query = [System.Web.HttpUtility]::ParseQueryString(([uri]$Link).Query)

function Test-Web([string]$u) { $u -match '^https?://' }

$url = $query['url']
if (-not (Test-Web $url)) { exit }

# Kodik (animelib и др.): плеер часто начинает с 360p, а на сервере есть лучше.
$kodik = '/(\d{3,4})\.mp4:hls:manifest\.m3u8'
if ($url -match $kodik) {
    foreach ($q in '1080', '720', '480') {
        $candidate = $url -replace $kodik, "/$q.mp4:hls:manifest.m3u8"
        try {
            Invoke-WebRequest -Uri $candidate -Method Head -UseBasicParsing -TimeoutSec 4 | Out-Null
            $url = $candidate
            break
        } catch { }
    }
}

$mpvArgs = @($config.args)
$start = 0.0
if ([double]::TryParse($query['start'], [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$start) -and $start -gt 1) {
    $mpvArgs += '--start=' + $start.ToString('0.0', [Globalization.CultureInfo]::InvariantCulture)
}
if (Test-Web $query['ref']) { $mpvArgs += "--referrer=$($query['ref'])" }
$title = "$($query['title'])".Trim()
if ($title) {
    if ($title.Length -gt 200) { $title = $title.Substring(0, 200) }
    $mpvArgs += "--force-media-title=$title"
}
$mpvArgs += '--', $url

# Кавычки для командной строки Windows (кавычки внутри значений экранируем).
$line = ($mpvArgs | ForEach-Object { '"' + ($_ -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"' }) -join ' '
Start-Process -FilePath $config.mpv -ArgumentList $line
