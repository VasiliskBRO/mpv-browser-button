# Обработчик ссылок mpvpip://play?url=<адрес>&start=<секунды>&ref=<страница>&title=<название>&list=<номера роликов YouTube через запятую>&q=<следующая серия>&qt=<её название>...
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
if (Test-Web $query['ref']) { $mpvArgs += "--referrer=$($query['ref'])" }

# Время и название относятся только к первому ролику.
$firstArgs = @()
$start = 0.0
if ([double]::TryParse($query['start'], [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$start) -and $start -gt 1) {
    $firstArgs += '--start=' + $start.ToString('0.0', [Globalization.CultureInfo]::InvariantCulture)
}
$title = "$($query['title'])".Trim()
if ($title) {
    if ($title.Length -gt 200) { $title = $title.Substring(0, 200) }
    $firstArgs += "--force-media-title=$title"
}

# Очередь YouTube: list=<номер>,<номер>,... — берём только настоящие номера роликов (11 знаков).
$queue = @("$($query['list'])" -split ',' | Where-Object { $_ -match '^[\w-]{11}$' } | Select-Object -Unique -First 500)
# Следующие серии (AnimeLIB): q=<адрес> и qt=<название> парами, в том же порядке.
$next = @($query.GetValues('q') | Where-Object { $_ })
$nextTitles = @($query.GetValues('qt'))
if ($queue.Count -gt 1 -and ([uri]$url).Host -match '(^|\.)youtube\.com$') {
    # --{ ... --} — настройки только для первого ролика; остальные идут следом в плейлист.
    $mpvArgs += @('--{') + $firstArgs + $url + '--}'
    $mpvArgs += $queue | Select-Object -Skip 1 | ForEach-Object { "https://www.youtube.com/watch?v=$_" }
} elseif ($next.Count -gt 0) {
    $mpvArgs += @('--{') + $firstArgs + $url + '--}'
    for ($i = 0; $i -lt [Math]::Min($next.Count, 100); $i++) {
        if (-not (Test-Web $next[$i])) { break }
        $t = "$($nextTitles[$i])".Trim()
        if ($t.Length -gt 200) { $t = $t.Substring(0, 200) }
        $mpvArgs += @('--{') + $(if ($t) { "--force-media-title=$t" }) + $next[$i] + '--}'
    }
} else {
    $mpvArgs += $firstArgs + '--', $url
}

# Кавычки для командной строки Windows (кавычки внутри значений экранируем).
$line = ($mpvArgs | ForEach-Object { '"' + ($_ -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"' }) -join ' '
Start-Process -FilePath $config.mpv -ArgumentList $line
