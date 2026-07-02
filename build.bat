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

REM ---- Step 3: Create kdb+ import library for linking ---------------------
REM On Windows, kdb+ API symbols (ktn, krr, ss, etc.) live in q.exe and must
REM be resolved at link time via an import library.
echo [3/5] Creating kdb+ import library...
where dlltool >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: dlltool not found. Please install MinGW-w64 binutils.
    exit /b 1
)

REM Generate .def file declaring kdb+ symbols as exports of q.exe
(
echo LIBRARY "q.exe"
echo EXPORTS
echo   krr
echo   ktn
echo   ss
echo   kj
echo   ki
echo   knk
echo   xD
echo   xT
) > kdb.def

REM Create MinGW import library from .def
dlltool -m i386:x86-64 -d kdb.def -l libkdb.dll.a -D q.exe
if !errorlevel! neq 0 (
    echo ERROR: dlltool failed to create import library.
    exit /b 1
)

REM ---- Step 4: Compile qduck extension DLL --------------------------------
echo [4/5] Compiling qduck\qduck.w64.dll...
if not exist qduck mkdir qduck

REM -L. -lkdb   : resolves kdb+ API from libkdb.dll.a (import from q.exe)
REM duckdb.dll  : link directly against DuckDB DLL
REM -O2 -static-libgcc : optimize, avoid libgcc_s dependency
gcc -shared -o qduck\qduck.w64.dll src\c\qduck.c -I.\libduckdb -L. -lkdb libduckdb\duckdb.dll -O2 -static-libgcc
if !errorlevel! neq 0 (
    echo.
    echo ERROR: Compilation failed.
    exit /b 1
)
echo   Compiled successfully.

REM Cleanup build artifacts
if exist kdb.def del /Q kdb.def >nul 2>nul
if exist libkdb.dll.a del /Q libkdb.dll.a >nul 2>nul

REM ---- Step 5: Copy DuckDB DLL alongside the extension --------------------
echo [5/5] Copying duckdb.dll to qduck\...
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
