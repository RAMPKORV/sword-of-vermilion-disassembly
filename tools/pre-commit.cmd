@echo off
REM pre-commit hook for Sword of Vermilion disassembly (Windows)
REM Runs all lint checks and the bit-perfect ROM verification before each commit.
REM
REM Installation (from repo root, run in cmd.exe):
REM   copy tools\pre-commit.cmd .git\hooks\pre-commit
REM
REM Git for Windows executes hooks as shell scripts, so use pre-commit.sh instead.
REM This file is provided as a reference for running checks manually on Windows:
REM   tools\pre-commit.cmd

setlocal enabledelayedexpansion

cd /d "%~dp0.."

echo --- pre-commit: running lint checks ---
node tools\run_checks.js
if errorlevel 1 (
    echo.
    echo pre-commit FAILED: lint checks did not pass.
    echo Fix the issues above and try again.
    exit /b 1
)

echo.
echo --- pre-commit: verifying bit-perfect ROM ---
call verify.bat
if errorlevel 1 (
    echo.
    echo pre-commit FAILED: ROM is not bit-perfect.
    echo Fix the build and try again. See docs\debugging_verify_failures.md
    exit /b 1
)

echo.
echo pre-commit: all checks passed.
exit /b 0
