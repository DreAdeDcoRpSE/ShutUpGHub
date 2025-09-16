@echo off
:: SPDX-License-Identifier: GPL-3.0-or-later
:: Copyright (C) 2025 headshotdomain.net
setlocal

:: Path to the JSON file
set "JSON_FILE=%LocalAppData%\LGHUB\integrations\applet_discord\config.json"
echo  _____ _           _   _   _       _____ _           _
echo /  ___^| ^|         ^| ^| ^| ^| ^| ^|     ^|  __ \ ^|         ^| ^|
echo \ `--.^| ^|__  _   _^| ^|_^| ^| ^| ^|_ __ ^| ^|  \/ ^|__  _   _^| ^|__
echo  `--. \ '_ \^| ^| ^| ^| __^| ^| ^| ^| '_ \^| ^| __^| '_ \^| ^| ^| ^| '_ \
echo /\__/ / ^| ^| ^| ^|_^| ^| ^|_^| ^|_^| ^| ^|_) ^| ^|_\ \ ^| ^| ^| ^|_^| ^| ^|_) ^|
echo \____/^|_^| ^|_^|\__,_^|\__^|\___/^| .__/ \____/_^| ^|_^|\__,_^|_.__/
echo                             ^| ^|
echo                             ^|_^|
echo This will take about 30 seconds due to needing to write in pauses that will
echo allow the program to shut down and restart without throwing errors.
echo.
echo.
echo Shutting down GHub.

:: Kill G Hub if running
taskkill /f /im lghub.exe >nul 2>&1
taskkill /f /im lghub_agent.exe >nul 2>&1
taskkill /f /im lghub_updater.exe >nul 2>&1

:: Wait to ensure processes are stopped
timeout /t 2 >nul
echo Lets give it a few seconds to full shut down.
timeout /t 5 >nul

:: If file doesn't exist, exit
if not exist "%JSON_FILE%" (
    echo ERROR: config.json not found at %JSON_FILE%
    pause
    exit /b
)

echo File found, removing any Read Only that might be on it.
:: Remove read-only if set
attrib -r "%JSON_FILE%" >nul 2>&1
timeout /t 2 >nul

:: Check if "enabled": false is already present
powershell -Command ^
    "$c = Get-Content -Raw '%JSON_FILE%';" ^
    "if ($c -match '\"enabled\"\s*:\s*false') { exit 0 } else { exit 1 }"
if %errorlevel%==0 (
    echo Already set to false.
) else (
    echo Changing enabled to false...
    powershell -Command "$lines=Get-Content '%JSON_FILE%'; $depth=0; $found=$false; $lines=$lines | ForEach-Object { if ($_ -match '{') { $depth++ }; if (-not $found -and $depth -eq 1 -and $_ -match '\"enabled\"\s*:\s*true') { $_ = $_ -replace '\"enabled\"\s*:\s*true','\"enabled\": false'; $found=$true }; if ($_ -match '}') { $depth-- }; $_ }; Set-Content -Encoding UTF8 '%JSON_FILE%' $lines"

)
timeout /t 2 >nul
:: Set the file back to read-only
attrib +r "%JSON_FILE%"
echo setting the file to Read Only.
:: Wait before restarting G Hub
timeout /t 2 >nul
echo waiting 10 seconds to give time for the GHub backend to catch up so we don't get errors.
powershell -Command "for ($i=9; $i -ge 0; $i--) { Write-Host -NoNewline $i; Start-Sleep -Seconds 1; Write-Host -NoNewline ((1..$i.ToString().Length | ForEach-Object { [char]8 }) -join '') }; Write-Host 'Restarting GHub'"
:: Restart G Hub
start "" "%ProgramFiles%\LGHUB\lghub.exe" >nul 2>&1
echo Done...
timeout /t 2 >nul
echo.
echo [93m[INFO][0m Just note, Next time GHub updates, you will need to run this.
echo They do love resetting this every time.
timeout /t 2 >nul
echo.
pause
