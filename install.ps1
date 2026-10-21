# Установка: находит mpv, кладёт обработчик в %LOCALAPPDATA%\mpv-browser-button
# и учит Windows открывать ссылки mpvpip:// этим обработчиком (только для текущего пользователя).
# Запуск: правой кнопкой по файлу → «Выполнить с помощью PowerShell»
#   или: powershell -ExecutionPolicy Bypass -File install.ps1 [-Mpv "C:\путь\к\mpv.exe"]
param([string]$Mpv)

$ErrorActionPreference = 'Stop'
$dest = Join-Path $env:LOCALAPPDATA 'mpv-browser-button'

function Find-Mpv {
    $candidates = @(
        (Get-Command mpv.exe -ErrorAction SilentlyContinue).Source
        "$env:USERPROFILE\mpv\mpv.exe"
        "$env:USERPROFILE\scoop\apps\mpv\current\mpv.exe"
        "$env:ProgramFiles\mpv\mpv.exe"
        "$env:LOCALAPPDATA\Programs\mpv\mpv.exe"
        'C:\mpv\mpv.exe'
    )
    # mpv.com — консольная версия; рядом с ней лежит mpv.exe.
    $candidates = $candidates | Where-Object { $_ } | ForEach-Object { $_ -replace '\.com$', '.exe' }
    $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}

if (-not $Mpv) { $Mpv = Find-Mpv }
while (-not $Mpv -or -not (Test-Path -LiteralPath $Mpv)) {
    $Mpv = (Read-Host 'Не нашёл mpv.exe. Вставь полный путь к нему').Trim('" ')
}
$Mpv = (Resolve-Path -LiteralPath $Mpv).Path
Write-Host "mpv: $Mpv"
if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue) -and -not (Test-Path (Join-Path (Split-Path $Mpv) 'yt-dlp.exe'))) {
    Write-Host 'Внимание: yt-dlp не найден — YouTube, Twitch и т.п. не откроются. Поставь: winget install yt-dlp' -ForegroundColor Yellow
}

New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'mpvpip.ps1') -Destination $dest -Force

# Свои параметры mpv можно дописать в config.json → "args" (например "--ontop").
$configPath = Join-Path $dest 'config.json'
$args_ = @('--force-window=immediate')
if (Test-Path -LiteralPath $configPath) {
    $old = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($old.args) { $args_ = @($old.args) }
}
$json = [ordered]@{ mpv = $Mpv; args = $args_ } | ConvertTo-Json
[IO.File]::WriteAllText($configPath, $json, (New-Object Text.UTF8Encoding $false))

$key = 'HKCU:\Software\Classes\mpvpip'
New-Item -Path "$key\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path $key -Name '(default)' -Value 'URL:mpvpip (browser -> mpv)'
Set-ItemProperty -Path $key -Name 'URL Protocol' -Value ''
$handler = Join-Path $dest 'mpvpip.ps1'
$command = "conhost.exe --headless powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$handler`" `"%1`""
Set-ItemProperty -Path "$key\shell\open\command" -Name '(default)' -Value $command

Write-Host ''
Write-Host 'Готово. Осталось в браузере:' -ForegroundColor Green
Write-Host '  1. Поставить расширение Violentmonkey (или Tampermonkey).'
Write-Host '  2. Открыть ссылку на скрипт из README и нажать «Установить».'
Write-Host '  3. При первом нажатии кнопки разрешить браузеру открывать ссылки mpvpip («Всегда»).'
