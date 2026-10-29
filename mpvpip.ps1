# Обработчик ссылок mpvpip://play?url=<адрес>&start=<секунды>&ref=<страница>&title=<название>&list=<номера роликов YouTube через запятую>&q=<серия>&qt=<её название>&qv=<качества>...&pos=<какая открыта>
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
# Все серии (AnimeLIB): q=<адрес> и qt=<название> парами, pos — номер открытой сейчас (с нуля).
$items = @($query.GetValues('q') | Where-Object { $_ } | Select-Object -First 100)
$itemTitles = @($query.GetValues('qt'))
# qv — какие ещё качества есть у серии (2160/1080/720…): их переключает меню «Качество» в Prism.
$itemVariants = @($query.GetValues('qv'))
function Get-VariantArgs([int]$i) {
    $v = "$($itemVariants[$i])"
    if ($v -match '^\d{3,4}(/\d{3,4}){1,9}$') { "--script-opts-append=stream-quality-variants=$v" }
}
$pos = 0
$useItems = $items.Count -gt 1 -and [int]::TryParse("$($query['pos'])", [ref]$pos) -and $pos -ge 0 -and $pos -lt $items.Count -and
    -not ($items | Where-Object { -not (Test-Web $_) })
if ($queue.Count -gt 1 -and ([uri]$url).Host -match '(^|\.)youtube\.com$') {
    # --{ ... --} — настройки только для первого ролика; остальные идут следом в плейлист.
    $mpvArgs += @('--{') + $firstArgs + $url + '--}'
    $mpvArgs += $queue | Select-Object -Skip 1 | ForEach-Object { "https://www.youtube.com/watch?v=$_" }
} elseif ($useItems) {
    # Время и название из firstArgs — только у открытой серии, плейлист начинается с неё.
    $mpvArgs += "--playlist-start=$pos"
    for ($i = 0; $i -lt $items.Count; $i++) {
        if ($i -eq $pos) {
            $mpvArgs += @('--{') + $firstArgs + @(Get-VariantArgs $i) + $items[$i] + '--}'
            continue
        }
        $t = "$($itemTitles[$i])".Trim()
        if ($t.Length -gt 200) { $t = $t.Substring(0, 200) }
        $mpvArgs += @('--{') + $(if ($t) { "--force-media-title=$t" }) + @(Get-VariantArgs $i) + $items[$i] + '--}'
    }
} else {
    $mpvArgs += $firstArgs + '--', $url
}

# Кавычки для командной строки Windows (кавычки внутри значений экранируем).
$line = ($mpvArgs | ForEach-Object { '"' + ($_ -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"' }) -join ' '
Start-Process -FilePath $config.mpv -ArgumentList $line
