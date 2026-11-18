@echo off
setlocal
set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "TARGET_PLATFORM=windows"
set "NMAKE_ARGS="

set "FIRST=%~1"
if /I "%FIRST%"=="mac"     set "TARGET_PLATFORM=mac"
if /I "%FIRST%"=="windows" set "TARGET_PLATFORM=windows"
if /I "%FIRST%"=="android" set "TARGET_PLATFORM=android"
if /I "%FIRST%"=="html"    set "TARGET_PLATFORM=html"

if /I "%FIRST%"=="mac"     shift
if /I "%FIRST%"=="windows" shift
if /I "%FIRST%"=="android" shift
if /I "%FIRST%"=="html"    shift

:collect
if "%~1"=="" goto donecollect
set "NMAKE_ARGS=%NMAKE_ARGS% %~1"
shift
goto collect
:donecollect

set "BUILD_DIR=%ROOT%\build\lea-build-%TARGET_PLATFORM%"

call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"

if exist "%BUILD_DIR%\CMakeCache.txt" goto skipconfig

if not "%TARGET_PLATFORM%"=="html" goto normalconfig

:confightml
C:\Users\rafae\emsdk\upstream\emscripten\emcmake.exe cmake -S "%ROOT%" -B "%BUILD_DIR%" -G "NMake Makefiles" -DEMSCRIPTEN=ON
if errorlevel 1 exit /b 1
goto skipconfig

:normalconfig
cmake -S "%ROOT%" -B "%BUILD_DIR%" -G "NMake Makefiles"
if errorlevel 1 exit /b 1
goto skipconfig

:skipconfig
cd /d "%BUILD_DIR%"
nmake %NMAKE_ARGS%

if not "%TARGET_PLATFORM%"=="html" goto skipcopy
if exist "%ROOT%\build\html\index.html" copy /Y "%ROOT%\build\html\index.html" "%BUILD_DIR%\bin\index.html" >nul
echo HTML template copied to %BUILD_DIR%\bin\
:skipcopy
endlocal