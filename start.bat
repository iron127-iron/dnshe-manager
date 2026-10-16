@echo off
setlocal
title DNSHE-Manager (local)
chcp 65001 >nul 2>&1
cd /d "%~dp0"

echo ============================================================
echo   DNSHE-Manager  -  Local Launcher (no Cloudflare deploy)
echo   Panel : http://127.0.0.1:8787
echo ============================================================
echo.

rem --- 0. Node.js check -------------------------------------------------
where node >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Node.js not found. Please install Node.js >= 22.5 first.
    echo         https://nodejs.org/
    pause
    exit /b 1
)

rem --- 1. Install dependencies on first run -----------------------------
if not exist "node_modules" (
    echo [1/3] Installing backend dependencies...
    call npm install
    if errorlevel 1 goto :fail
)
if not exist "frontend\node_modules" (
    echo [1/3] Installing frontend dependencies...
    call npm install --prefix frontend
    if errorlevel 1 goto :fail
)

rem --- 2. Port check ----------------------------------------------------
netstat -ano | findstr /r /c:"LISTENING" | findstr /c:":8787" >nul 2>&1
if not errorlevel 1 (
    echo [OK] Server already running on port 8787 - opening browser only.
    start "" "http://127.0.0.1:8787"
    echo.
    pause
    exit /b 0
)

rem --- 3. Build + start -------------------------------------------------
echo [2/3] Building frontend and bundling backend...
call npm run build
if errorlevel 1 goto :fail

echo [3/3] Starting server at http://127.0.0.1:8787
echo       (data: %CD%\data\dnshe.db   key: %CD%\data\aes.key)
echo       Press Ctrl+C to stop.
echo.

rem Open the browser once the server responds.
start "" powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$i=0; while($i -lt 120){ try{ $r=Invoke-WebRequest -Uri 'http://127.0.0.1:8787/' -UseBasicParsing -TimeoutSec 1; if($r.StatusCode -eq 200){ Start-Process 'http://127.0.0.1:8787'; break } }catch{}; Start-Sleep -Milliseconds 500; $i++ }"

call npm run start:node
if errorlevel 1 goto :fail

echo.
echo Server stopped.
pause
exit /b 0

:fail
echo.
echo [ERROR] Something went wrong - see the messages above.
pause
exit /b 1
