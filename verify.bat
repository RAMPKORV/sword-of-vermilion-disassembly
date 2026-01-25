@echo off
REM Sword of Vermilion ROM Build Verification Script
REM Builds the ROM and verifies it matches the expected hash

setlocal enabledelayedexpansion

set EXPECTED_HASH=bcf1698a01a7e481240a4b01b3e68e31b133d289d9aaea7181e72a4057845eb4
set ROM_FILE=out.bin

echo Building ROM...
call asm68k /k /p /o ae- vermilion.asm,out.bin,,vermilion.lst
if errorlevel 1 (
    echo BUILD FAILED
    exit /b 1
)

echo.
echo Verifying ROM hash...

REM Use certutil to compute SHA256 hash
for /f "skip=1 tokens=*" %%a in ('certutil -hashfile %ROM_FILE% SHA256 2^>nul') do (
    if not defined ACTUAL_HASH (
        set "ACTUAL_HASH=%%a"
    )
)

REM Remove spaces from hash
set "ACTUAL_HASH=!ACTUAL_HASH: =!"

if /i "!ACTUAL_HASH!"=="!EXPECTED_HASH!" (
    echo.
    echo ========================================
    echo   BUILD VERIFIED - ROM IS BIT-PERFECT
    echo ========================================
    echo Hash: !ACTUAL_HASH!
    exit /b 0
) else (
    echo.
    echo ========================================
    echo   VERIFICATION FAILED - ROM MISMATCH
    echo ========================================
    echo Expected: !EXPECTED_HASH!
    echo Actual:   !ACTUAL_HASH!
    exit /b 1
)
