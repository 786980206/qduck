@echo off
setlocal enabledelayedexpansion

set DUCKDB_ZIP=libduckdb-windows-amd64.zip
set DUCKDB_URL=https://install.duckdb.org/v1.4.5/%DUCKDB_ZIP%

REM ---- Check prerequisites -----------------------------------------------
where gcc >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: gcc not found. Please install MinGW-w64.
    echo   https://www.mingw-w64.org/
    echo After installation, ensure MinGW-w64 bin is in your PATH.
    exit /b 1
)

echo =============================================
echo  Building qduck for Windows (64-bit)
echo =============================================
echo:

REM ---- Step 1: Download DuckDB library -----------------------------------
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

REM ---- Step 2: Extract DuckDB library ------------------------------------
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

REM Verify duckdb.h is present
if not exist libduckdb\duckdb.h (
    echo ERROR: duckdb.h not found in libduckdb\. Extraction may have failed.
    dir libduckdb\
    exit /b 1
)

REM ---- Step 3: Compile qduck extension DLL --------------------------------
echo [3/4] Compiling qduck\qduck.w64.dll...
if not exist qduck mkdir qduck

gcc -shared -o qduck\qduck.w64.dll src\c\qduck.c -I.\libduckdb libduckdb\duckdb.dll -O2 -static-libgcc
if !errorlevel! neq 0 (
    echo.
    echo ERROR: Compilation failed.
    exit /b 1
)
echo   Compiled successfully.

REM ---- Step 4: Copy DuckDB DLL alongside the extension --------------------
echo [4/4] Copying duckdb.dll to qduck\...
if not exist libduckdb\duckdb.dll (
    echo WARNING: duckdb.dll not found.
    dir libduckdb\
) else (
    copy /Y libduckdb\duckdb.dll qduck\ >nul
    echo   Copied duckdb.dll
)

echo:
echo =============================================
echo  Build complete!
echo =============================================
echo:
echo Output in qduck\:
echo   qduck.w64.dll    - qduck extension for kdb+/q
echo   duckdb.dll       - DuckDB dynamic library
echo   init.q           - q module loader
echo:
echo To use in q:
echo   .x: use `qduck
echo   .x.e "select 42"
echo:
endlocal
