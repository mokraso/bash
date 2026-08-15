@echo off
setlocal EnableExtensions EnableDelayedExpansion

title Auto Install - Git + Node.js + Claude Code

:: ============================================================
:: CONFIG
:: ============================================================

set "LOGFILE=%~dp0install-dev-tools.log"

set "GIT_URL=https://git-scm.com/install/windows"
set "NODE_URL=https://nodejs.org/"
set "CLAUDE_URL=https://docs.anthropic.com/en/docs/claude-code/overview"

:: Status:
:: 0 = NOT CHECKED
:: 1 = SUCCESS / INSTALLED
:: 2 = ALREADY INSTALLED
:: 3 = FAILED

set "GIT_STATUS=0"
set "NODE_STATUS=0"
set "CLAUDE_STATUS=0"

echo ============================================================ > "%LOGFILE%"
echo Install started: %DATE% %TIME% >> "%LOGFILE%"
echo ============================================================ >> "%LOGFILE%"

:: ============================================================
:: ADMIN CHECK
:: ============================================================

net session >nul 2>&1

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [INFO] Requesting Administrator permission...
    echo.

    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Start-Process -FilePath '%~f0' -Verb RunAs"

    exit /b 0
)

:: ============================================================
:: HEADER
:: ============================================================

cls

echo.
echo ============================================================
echo.
echo          DEVELOPMENT TOOLS AUTO INSTALLER
echo.
echo          [1] Git
echo          [2] Node.js LTS + npm
echo          [3] Claude Code CLI
echo.
echo ============================================================
echo.

echo Running as Administrator.
echo.

:: ============================================================
:: CHECK WINGET
:: ============================================================

where winget >nul 2>&1

if %ERRORLEVEL% EQU 0 (
    set "WINGET_AVAILABLE=1"
    echo [OK] winget is available.
) else (
    set "WINGET_AVAILABLE=0"
    echo [WARNING] winget is not available.
    echo [WARNING] Automatic installation using winget may fail.
)

echo.


:: ============================================================
:: ============================================================
::                       GIT
:: ============================================================
:: ============================================================

echo ============================================================
echo [1/3] GIT
echo ============================================================
echo.

set "GIT_EXE="

:: ------------------------------------------------------------
:: Check Git in PATH
:: ------------------------------------------------------------

where git >nul 2>&1

if %ERRORLEVEL% EQU 0 (
    for /f "delims=" %%G in ('where git 2^>nul') do (
        set "GIT_EXE=%%G"
        goto GIT_ALREADY_FOUND
    )
)

:: ------------------------------------------------------------
:: Check common Git locations
:: ------------------------------------------------------------

if exist "%ProgramFiles%\Git\cmd\git.exe" (
    set "GIT_EXE=%ProgramFiles%\Git\cmd\git.exe"
    goto GIT_ALREADY_FOUND
)

if exist "%ProgramFiles%\Git\bin\git.exe" (
    set "GIT_EXE=%ProgramFiles%\Git\bin\git.exe"
    goto GIT_ALREADY_FOUND
)

if exist "%LocalAppData%\Programs\Git\cmd\git.exe" (
    set "GIT_EXE=%LocalAppData%\Programs\Git\cmd\git.exe"
    goto GIT_ALREADY_FOUND
)

goto GIT_INSTALL


:GIT_ALREADY_FOUND

set "GIT_STATUS=2"

echo [OK] Git is already installed.
echo [PATH] %GIT_EXE%
echo [VERSION]
"%GIT_EXE%" --version

echo Git already installed: %GIT_EXE% >> "%LOGFILE%"

:: Add Git to current PATH
for %%A in ("%GIT_EXE%") do set "GIT_DIR=%%~dpA"
set "PATH=%GIT_DIR%;%PATH%"

goto GIT_DONE


:: ------------------------------------------------------------
:: Install Git
:: ------------------------------------------------------------

:GIT_INSTALL

echo [INFO] Git was not found.
echo [INFO] Attempting automatic installation...
echo.

if "%WINGET_AVAILABLE%"=="1" (

    winget install ^
        --id Git.Git ^
        -e ^
        --source winget ^
        --accept-source-agreements ^
        --accept-package-agreements

    set "GIT_WINGET_RESULT=!ERRORLEVEL!"

    echo [INFO] winget exit code: !GIT_WINGET_RESULT!
    echo Git winget exit code: !GIT_WINGET_RESULT! >> "%LOGFILE%"
)

:: ------------------------------------------------------------
:: IMPORTANT:
:: Do not rely on PATH after installation.
:: Search the actual executable.
:: ------------------------------------------------------------

if exist "%ProgramFiles%\Git\cmd\git.exe" (
    set "GIT_EXE=%ProgramFiles%\Git\cmd\git.exe"
    goto GIT_INSTALL_SUCCESS
)

if exist "%ProgramFiles%\Git\bin\git.exe" (
    set "GIT_EXE=%ProgramFiles%\Git\bin\git.exe"
    goto GIT_INSTALL_SUCCESS
)

if exist "%LocalAppData%\Programs\Git\cmd\git.exe" (
    set "GIT_EXE=%LocalAppData%\Programs\Git\cmd\git.exe"
    goto GIT_INSTALL_SUCCESS
)

:: Check again through PATH
where git >nul 2>&1

if %ERRORLEVEL% EQU 0 (
    for /f "delims=" %%G in ('where git 2^>nul') do (
        set "GIT_EXE=%%G"
        goto GIT_INSTALL_SUCCESS
    )
)

:: ------------------------------------------------------------
:: Git failed
:: ------------------------------------------------------------

set "GIT_STATUS=3"

echo.
echo [FAILED] Git installation could not be verified.
echo.
echo Download:
echo %GIT_URL%

echo Git installation FAILED. Download: %GIT_URL% >> "%LOGFILE%"

goto GIT_DONE


:GIT_INSTALL_SUCCESS

set "GIT_STATUS=1"

echo.
echo [SUCCESS] Git installed successfully.
echo [PATH] %GIT_EXE%
echo [VERSION]

"%GIT_EXE%" --version

echo Git installation SUCCESS: %GIT_EXE% >> "%LOGFILE%"

for %%A in ("%GIT_EXE%") do set "GIT_DIR=%%~dpA"
set "PATH=%GIT_DIR%;%PATH%"

:GIT_DONE

echo.


:: ============================================================
:: ============================================================
::                    NODE.JS + NPM
:: ============================================================
:: ============================================================

echo ============================================================
echo [2/3] NODE.JS LTS + NPM
echo ============================================================
echo.

set "NODE_EXE="

:: ------------------------------------------------------------
:: Check Node.js in PATH
:: ------------------------------------------------------------

where node >nul 2>&1

if %ERRORLEVEL% EQU 0 (
    for /f "delims=" %%N in ('where node 2^>nul') do (
        set "NODE_EXE=%%N"
        goto NODE_ALREADY_FOUND
    )
)

:: ------------------------------------------------------------
:: Check common locations
:: ------------------------------------------------------------

if exist "%ProgramFiles%\nodejs\node.exe" (
    set "NODE_EXE=%ProgramFiles%\nodejs\node.exe"
    goto NODE_ALREADY_FOUND
)

if exist "%LocalAppData%\Programs\nodejs\node.exe" (
    set "NODE_EXE=%LocalAppData%\Programs\nodejs\node.exe"
    goto NODE_ALREADY_FOUND
)

goto NODE_INSTALL


:NODE_ALREADY_FOUND

set "NODE_STATUS=2"

echo [OK] Node.js is already installed.
echo [PATH] %NODE_EXE%
echo [VERSION]

"%NODE_EXE%" --version

for %%A in ("%NODE_EXE%") do set "NODE_DIR=%%~dpA"

set "PATH=%NODE_DIR%;%PATH%"

:: Check npm
if exist "%NODE_DIR%npm.cmd" (
    echo [OK] npm found.
    call "%NODE_DIR%npm.cmd" --version
) else (
    echo [WARNING] Node.js found but npm was not found.
    echo [WARNING] Claude Code may not be installable.
)

echo Node.js already installed: %NODE_EXE% >> "%LOGFILE%"

goto NODE_DONE


:: ------------------------------------------------------------
:: Install Node.js
:: ------------------------------------------------------------

:NODE_INSTALL

echo [INFO] Node.js was not found.
echo [INFO] Attempting automatic installation...
echo.

if "%WINGET_AVAILABLE%"=="1" (

    winget install ^
        --id OpenJS.NodeJS.LTS ^
        -e ^
        --source winget ^
        --accept-source-agreements ^
        --accept-package-agreements

    set "NODE_WINGET_RESULT=!ERRORLEVEL!"

    echo [INFO] winget exit code: !NODE_WINGET_RESULT!
    echo Node.js winget exit code: !NODE_WINGET_RESULT! >> "%LOGFILE%"
)

:: ------------------------------------------------------------
:: Search actual Node executable
:: ------------------------------------------------------------

if exist "%ProgramFiles%\nodejs\node.exe" (
    set "NODE_EXE=%ProgramFiles%\nodejs\node.exe"
    goto NODE_INSTALL_SUCCESS
)

if exist "%LocalAppData%\Programs\nodejs\node.exe" (
    set "NODE_EXE=%LocalAppData%\Programs\nodejs\node.exe"
    goto NODE_INSTALL_SUCCESS
)

where node >nul 2>&1

if %ERRORLEVEL% EQU 0 (
    for /f "delims=" %%N in ('where node 2^>nul') do (
        set "NODE_EXE=%%N"
        goto NODE_INSTALL_SUCCESS
    )
)

:: ------------------------------------------------------------
:: Node.js failed
:: ------------------------------------------------------------

set "NODE_STATUS=3"

echo.
echo [FAILED] Node.js installation could not be verified.
echo.
echo Download:
echo %NODE_URL%

echo Node.js installation FAILED. Download: %NODE_URL% >> "%LOGFILE%"

goto NODE_DONE


:NODE_INSTALL_SUCCESS

set "NODE_STATUS=1"

echo.
echo [SUCCESS] Node.js installed successfully.
echo [PATH] %NODE_EXE%
echo [VERSION]

"%NODE_EXE%" --version

for %%A in ("%NODE_EXE%") do set "NODE_DIR=%%~dpA"

set "PATH=%NODE_DIR%;%PATH%"

:: Verify npm

if exist "%NODE_DIR%npm.cmd" (
    echo [OK] npm found.
    echo [VERSION]
    call "%NODE_DIR%npm.cmd" --version
) else (
    echo [WARNING] npm was not found.
)

echo Node.js installation SUCCESS: %NODE_EXE% >> "%LOGFILE%"

:NODE_DONE

echo.


:: ============================================================
:: ============================================================
::                       CLAUDE CODE
:: ============================================================
:: ============================================================

echo ============================================================
echo [3/3] CLAUDE CODE CLI
echo ============================================================
echo.

set "CLAUDE_EXE="

:: ------------------------------------------------------------
:: Check Claude Code in PATH
:: ------------------------------------------------------------

where claude >nul 2>&1

if %ERRORLEVEL% EQU 0 (
    for /f "delims=" %%C in ('where claude 2^>nul') do (
        set "CLAUDE_EXE=%%C"
        goto CLAUDE_ALREADY_FOUND
    )
)

:: ------------------------------------------------------------
:: Check common npm locations
:: ------------------------------------------------------------

if exist "%AppData%\npm\claude.cmd" (
    set "CLAUDE_EXE=%AppData%\npm\claude.cmd"
    goto CLAUDE_ALREADY_FOUND
)

if exist "%AppData%\npm\claude.exe" (
    set "CLAUDE_EXE=%AppData%\npm\claude.exe"
    goto CLAUDE_ALREADY_FOUND
)

:: ------------------------------------------------------------
:: Claude not found -> check npm
:: ------------------------------------------------------------

goto CLAUDE_INSTALL


:CLAUDE_ALREADY_FOUND

set "CLAUDE_STATUS=2"

echo [OK] Claude Code is already installed.
echo [PATH] %CLAUDE_EXE%
echo [VERSION]

call "%CLAUDE_EXE%" --version

for %%A in ("%CLAUDE_EXE%") do set "CLAUDE_DIR=%%~dpA"
set "PATH=%CLAUDE_DIR%;%PATH%"

echo Claude Code already installed: %CLAUDE_EXE% >> "%LOGFILE%"

goto CLAUDE_DONE


:: ------------------------------------------------------------
:: Install Claude Code
:: ------------------------------------------------------------

:CLAUDE_INSTALL

:: Need npm
where npm >nul 2>&1

if %ERRORLEVEL% NEQ 0 (

    echo [FAILED] npm is not available.
    echo [INFO] Claude Code cannot be installed automatically.
    echo.
    echo Download Node.js:
    echo %NODE_URL%
    echo.
    echo Claude Code:
    echo %CLAUDE_URL%

    set "CLAUDE_STATUS=3"

    echo Claude Code FAILED - npm unavailable. >> "%LOGFILE%"

    goto CLAUDE_DONE
)

echo [INFO] Claude Code was not found.
echo [INFO] Installing Claude Code CLI...
echo.

call npm install -g @anthropic-ai/claude-code

set "CLAUDE_NPM_RESULT=!ERRORLEVEL!"

echo.
echo [INFO] npm exit code: !CLAUDE_NPM_RESULT!

echo Claude Code npm exit code: !CLAUDE_NPM_RESULT! >> "%LOGFILE%"

:: ------------------------------------------------------------
:: Find Claude after installation
:: ------------------------------------------------------------

where claude >nul 2>&1

if %ERRORLEVEL% EQU 0 (
    for /f "delims=" %%C in ('where claude 2^>nul') do (
        set "CLAUDE_EXE=%%C"
        goto CLAUDE_INSTALL_SUCCESS
    )
)

if exist "%AppData%\npm\claude.cmd" (
    set "CLAUDE_EXE=%AppData%\npm\claude.cmd"
    goto CLAUDE_INSTALL_SUCCESS
)

if exist "%AppData%\npm\claude.exe" (
    set "CLAUDE_EXE=%AppData%\npm\claude.exe"
    goto CLAUDE_INSTALL_SUCCESS
)

:: ------------------------------------------------------------
:: Claude failed
:: ------------------------------------------------------------

set "CLAUDE_STATUS=3"

echo.
echo [FAILED] Claude Code installation could not be verified.
echo.
echo Documentation:
echo %CLAUDE_URL%

echo Claude Code installation FAILED. Docs: %CLAUDE_URL% >> "%LOGFILE%"

goto CLAUDE_DONE


:CLAUDE_INSTALL_SUCCESS

set "CLAUDE_STATUS=1"

echo.
echo [SUCCESS] Claude Code installed successfully.
echo [PATH] %CLAUDE_EXE%
echo [VERSION]

call "%CLAUDE_EXE%" --version

for %%A in ("%CLAUDE_EXE%") do set "CLAUDE_DIR=%%~dpA"
set "PATH=%CLAUDE_DIR%;%PATH%"

:CLAUDE_DONE

echo.


:: ============================================================
:: FINAL REPORT
:: ============================================================

echo.
echo ============================================================
echo                     FINAL REPORT
echo ============================================================
echo.

:: ---------------- Git ----------------

echo Git:

if "%GIT_STATUS%"=="1" (
    echo     [SUCCESS] Installed during this run.
)

if "%GIT_STATUS%"=="2" (
    echo     [ALREADY INSTALLED]
)

if "%GIT_STATUS%"=="3" (
    echo     [FAILED]
    echo     Download: %GIT_URL%
)

echo.

:: ---------------- Node ----------------

echo Node.js + npm:

if "%NODE_STATUS%"=="1" (
    echo     [SUCCESS] Installed during this run.
)

if "%NODE_STATUS%"=="2" (
    echo     [ALREADY INSTALLED]
)

if "%NODE_STATUS%"=="3" (
    echo     [FAILED]
    echo     Download: %NODE_URL%
)

echo.

:: ---------------- Claude ----------------

echo Claude Code CLI:

if "%CLAUDE_STATUS%"=="1" (
    echo     [SUCCESS] Installed during this run.
)

if "%CLAUDE_STATUS%"=="2" (
    echo     [ALREADY INSTALLED]
)

if "%CLAUDE_STATUS%"=="3" (
    echo     [FAILED]
    echo     Documentation: %CLAUDE_URL%
)

echo.
echo ============================================================
echo.

:: ============================================================
:: FAILURE SUMMARY
:: ============================================================

set "FAIL_COUNT=0"

if "%GIT_STATUS%"=="3" set /a FAIL_COUNT+=1
if "%NODE_STATUS%"=="3" set /a FAIL_COUNT+=1
if "%CLAUDE_STATUS%"=="3" set /a FAIL_COUNT+=1

if "%FAIL_COUNT%"=="0" (

    echo [SUCCESS] All requested tools are ready.

) else (

    echo [WARNING] %FAIL_COUNT% tool(s) failed.
    echo.
    echo Failed tools:

    if "%GIT_STATUS%"=="3" (
        echo.
        echo   Git
        echo   Download:
        echo   %GIT_URL%
    )

    if "%NODE_STATUS%"=="3" (
        echo.
        echo   Node.js
        echo   Download:
        echo   %NODE_URL%
    )

    if "%CLAUDE_STATUS%"=="3" (
        echo.
        echo   Claude Code
        echo   Documentation:
        echo   %CLAUDE_URL%
    )
)

echo.
echo Log file:
echo %LOGFILE%

echo.
echo ============================================================
echo.

set "SSH_DIR=%USERPROFILE%\.ssh"
set "SSH_KEY=%SSH_DIR%\id_ed25519"
set "SSH_PUB=%SSH_DIR%\id_ed25519.pub"

:: Tạo .ssh nếu chưa tồn tại
if not exist "%SSH_DIR%" (
    mkdir "%SSH_DIR%"
)

:: Chỉ tạo key nếu chưa tồn tại
if exist "%SSH_KEY%" (
    echo [OK] SSH key already exists:
    echo      %SSH_KEY%
) else (
    echo [INFO] Generating SSH key...

    ssh-keygen -t ed25519 ^
        -f "%SSH_KEY%" ^
        -N "" ^
        -q

    if errorlevel 1 (
        echo [FAILED] SSH key generation failed.
    ) else (
        echo [SUCCESS] SSH key generated.
        echo.
        echo Private key:
        echo %SSH_KEY%
        echo.
        echo Public key:
        echo %SSH_PUB%
    )
)

pause
echo Finished: %DATE% %TIME% >> "%LOGFILE%"

pause

endlocal
exit /b 0
