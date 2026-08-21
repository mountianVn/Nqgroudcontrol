@echo off
setlocal EnableExtensions

cd /d "%~dp0"

echo ========================================
echo Push QGroundControl to GitHub
echo ========================================

set "REMOTE_NAME=github-user"
set "REMOTE_URL=https://github.com/mountianVn/Nqgroudcontrol.git"

git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo Error: this script must be run from a Git repository.
    goto :error
)

git remote get-url "%REMOTE_NAME%" >nul 2>&1
if errorlevel 1 (
    git remote add "%REMOTE_NAME%" "%REMOTE_URL%"
) else (
    git remote set-url "%REMOTE_NAME%" "%REMOTE_URL%"
)
if errorlevel 1 goto :error

rem Stage project files, then explicitly remove build output from the index.
git add -A -- .
if errorlevel 1 (
    echo Error: unable to stage project files.
    goto :error
)
git restore --staged -- build/ >nul 2>&1
git restore --staged -- Build/ >nul 2>&1
git reset -- build/ Build/ >nul 2>&1

rem Keep generated build folders out even if they were previously tracked.
for /d /r %%D in (build Build) do (
    if exist "%%D" git reset -- "%%D" >nul 2>&1
)

git diff --cached --quiet
if errorlevel 1 (
    git commit -m "chore: sync project files"
    if errorlevel 1 goto :error
)

git push -u "%REMOTE_NAME%" HEAD:main
if errorlevel 1 goto :error

echo.
echo Push completed successfully.
echo The window will remain open so you can review the result.
pause
exit /b 0

:error
echo.
echo Push failed. Review the message above and try again.
pause
exit /b 1
