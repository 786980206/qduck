@echo off
setlocal enabledelayedexpansion

set DUCKDB_ZIP=libduckdb-windows-amd64.zip
set DUCKDB_URL=https://install.duckdb.org/v1.4.5/%DUCKDB_ZIP%

:: ── Check prerequisites ─────────────────────────────────────────────────────────
where gcc >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: gcc not found. Please install MinGW-w64 (https://www.mingw-w64.org/).
    echo After installation, ensure the MinGW-w64 bin directory (e.g. C:\msys64\mingw64\bin^) is in your PATH.
    exit /b 1
)

echo =============================================
echo  Building qduck for Windows (64-bit)
echo =============================================
echo.

:: ── Step 1: Download DuckDB library ────────────────────────────────────────────
if not exist "%DUCKDB_ZIP%" (
    echo [1/4] Downloading DuckDB library from:
    echo   %DUCKDB_URL%
    powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%DUCKDB_URL%' -OutFile '%DUCKDB_ZIP%'}"
    if !errorlevel! neq 0 (
        echo ERROR: Failed to download DuckDB library.
        exit /b 1
    )
    echo   Saved to %DUCKDB_ZIP%
) else (
    echo [1/4] %DUCKDB_ZIP% already exists, skipping download.
)

:: ── Step 2: Extract DuckDB library ─────────────────────────────────────────────
if not exist "libduckdb\" (
    echo [2/4] Extracting %DUCKDB_ZIP% to libduckdb\...
    powershell -Command "Expand-Archive -Path '%DUCKDB_ZIP%' -DestinationPath 'libduckdb' -Force"
    if !errorlevel! neq 0 (
        echo ERROR: Failed to extract DuckDB library.
        exit /b 1
    )
) else (
    echo [2/4] libduckdb\ already exists, skipping extraction.
)

:: Verify the extracted libduckdb directory has the expected files
if not exist libduckdb\duckdb.h (
    echo ERROR: duckdb.h not found in libduckdb\. Extraction may have failed.
    echo Contents of libduckdb\:
    dir libduckdb\
    exit /b 1
)

:: ── Step 3: Compile qduck extension DLL ────────────────────────────────────────
echo [3/4] Compiling qduck\qduck.w64.dll...
if not exist qduck mkdir qduck

:: -shared          : Build a DLL
:: -o qduck\qduck.w64.dll : Output (kdb+ on Windows loads via init.q -> qduck.w64 -> qduck.w64.dll)
:: -I.\libduckdb    : DuckDB C header
:: libduckdb\duckdb.dll : Link directly against the DuckDB DLL (MinGW-w64 supports this)
:: -O2              : Optimize
:: -static-libgcc   : Avoid runtime dependency on libgcc_s_seh-1.dll
gcc -shared -o qduck\qduck.w64.dll src\c\qduck.c -I.\libduckdb libduckdb\duckdb.dll -O2 -static-libgcc
if !errorlevel! neq 0 (
    echo.
    echo ERROR: Compilation failed.
    echo.
    echo Possible issues:
    echo   1. MinGW-w64 gcc is too old - try updating.
    echo   2. duckdb.dll is incompatible with your gcc version.
    echo   3. Missing 32-bit/64-bit mismatch (use 64-bit MinGW-w64).
    exit /b 1
)
echo   Compiled successfully.

:: ── Step 4: Copy DuckDB DLL alongside the extension ────────────────────────────
echo [4/4] Copying duckdb.dll to qduck\...
if not exist libduckdb\duckdb.dll (
    echo WARNING: duckdb.dll not found in libduckdb\ (unexpected archive layout).
    echo Contents of libduckdb\:
    dir libduckdb\
) else (
    copy /Y libduckdb\duckdb.dll qduck\ >nul
    echo   Copied duckdb.dll
)

echo.
echo =============================================
echo  Build complete!
echo =============================================
echo.
echo Output in qduck\:
echo   qduck.w64.dll    - qduck extension for kdb+/q
echo   duckdb.dll       - DuckDB dynamic library (must be co-located)
echo   init.q           - q module loader
echo.
echo To use in q:
echo   .x: use `qduck
echo   .x.e \"select 42\"
echo.
endlocal
