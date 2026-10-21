# Удаление: убирает ссылки mpvpip:// из реестра и папку с обработчиком.
# Сам скрипт кнопки удаляется в Violentmonkey (значок → панель управления → корзина).

$key = 'HKCU:\Software\Classes\mpvpip'
if (Test-Path $key) { Remove-Item -Path $key -Recurse -Force }
$dest = Join-Path $env:LOCALAPPDATA 'mpv-browser-button'
if (Test-Path $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
Write-Host 'Удалено. Не забудь удалить скрипт кнопки в Violentmonkey.' -ForegroundColor Green
