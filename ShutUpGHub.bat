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
echo.

:: Check if the JSON file exists
if not exist "%JSON_FILE%" (
    echo.
    echo [91m[ERROR][0m: config.json not found at the expected location:
    echo %JSON_FILE%
    echo.
    echo [93m[SOLUTION][0m: You need to update this script with the correct file location.
    echo.
    echo [96m[INSTRUCTIONS][0m:
    echo 1. Find your LGHUB installation directory
    echo    Common locations:
    echo    - %LocalAppData%\LGHUB\integrations\applet_discord\config.json
    echo    - %ProgramFiles%\LGHUB\integrations\applet_discord\config.json
    echo    - %ProgramFiles^(x86^)%\LGHUB\integrations\applet_discord\config.json
    echo.
    echo 2. Once you find the correct path, edit this batch file:
    echo    - Right-click this .bat file and select "Edit"
    echo    - Find the line that starts with: set "JSON_FILE=
    echo    - Replace the path with your correct path
    echo    - Save the file and run it again
    echo.
    echo 3. Alternative: Search for the file manually:
    echo    - Press Win+R, type: %%LocalAppData%%\LGHUB
    echo    - Look for: integrations\applet_discord\config.json
    echo    - If not there, check Program Files locations above
    echo.
    echo [33m[TIP][0m: Make sure LGHUB is installed. No reason to run this if you're not even using LGHub
    echo.
    pause
    exit /b 1
)

echo This will take about 30 seconds due to needing to write in pauses that will
echo allow the program to shut down and restart without throwing errors.
echo.

:SHOULDWEPROCEED
echo [33m^[NOTE^][0m:
echo There is a chance that your audio sources may be changed. Though slim,
echo it was reported and I decided to put in this warning that you may need
echo to change your Discords audio input/output after you run this.
echo.
set choice=
set /p choice=Would you like to continue?  [33m^[Y/N^][0m:
if NOT '%choice%'=='' set "choice=%choice:~0,1%"
if /i '%choice%'=='Y' GOTO PROCEED
if /i '%choice%'=='N' exit /b
if '%choice%'=='' GOTO SHOULDWEPROCEED
echo "%choice%" is not valid
echo.
GOTO SHOULDWEPROCEED

:PROCEED
timeout /t 2 >nul
echo Checking if Discord is running first...

tasklist /FI "IMAGENAME eq Discord.exe" 2>NUL | find /I "Discord.exe" >NUL
if %ERRORLEVEL%==0 (
    echo Discord is running. Killing process...
    :: Kill Discord.exe
    taskkill /F /IM Discord.exe >NUL 2>&1
    timeout /t 6 >nul
    echo Verifying Discord shutdown...

    rem Try up to 3 times (5s each)
    rem If you adjust this later, You can see I put 6 instead of 5 for 5 seconds,
    rem because it’s a countdown that includes the current second. Sof for 5 seconds,
    rem add a +1 to the number.
    for /L %%i in (1,1,3) do (
        timeout /t 6 >nul
        tasklist /FI "IMAGENAME eq Discord.exe" 2>NUL | find /I "Discord.exe" >NUL
        if errorlevel 1 (
            echo [92m[SUCCESS][0m: Discord has been terminated.
            goto DiscordDone
        ) else (
            echo.
            echo Discord appears to be still running.
            echo Waiting another 5 seconds for Discord to shut down. ^(attempt %%i of 3^)
        )
    )
    echo.
    timeout /t 3 >nu
    echo [91m[ERROR][0m: Failed to terminate Discord. Please close it manually and run this script again.
    pause
    exit /b 1
) else (
    echo Discord is not running.
)

:DiscordDone
timeout /t 2 >nul
echo.
echo Shutting down GHub.

:: Kill G Hub if running
taskkill /f /im lghub.exe >nul 2>&1
taskkill /f /im lghub_agent.exe >nul 2>&1
taskkill /f /im lghub_updater.exe >nul 2>&1

:: Wait to ensure processes are stopped
timeout /t 2 >nul
echo Lets give it a few seconds to fully shut down.
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
    powershell -Command "(Get-Content -Raw '%JSON_FILE%') -replace '\"enabled\"\s*:\s*true','\"enabled\": false' | Set-Content -Encoding UTF8 '%JSON_FILE%'"
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
exit /b
