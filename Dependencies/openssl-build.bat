@echo off

setlocal

if "%VisualStudioVersion%" equ "" echo Please run this script from a Visual Studio command prompt for the compiler you want to use
if "%VisualStudioVersion%" equ "" exit /b 1

:: make perl.exe available via %PATH%
set PATH=%PATH%;%~dp0StrawberryPerl\perl\bin

if "%VSCMD_ARG_TGT_ARCH%" equ "x64" (
    set PLATFORM=x64
    set CONFIGURE=VC-WIN64A
    set SETUP=ms\do_win64a.bat
) else (
    set PLATFORM=Win32
    set CONFIGURE=VC-WIN32
    set SETUP=ms\do_ms.bat
)

set RUNTIME=d

pushd %~dp0openssl

::
:: Backup
::

if "%RUNTIME%" equ "d" copy /y ms\nt.mak ms\nt.mak.orig

::
:: Release
::

perl Configure %CONFIGURE% no-asm --prefix=%~dp0\%PLATFORM%-m%RUNTIME%
call %SETUP%

if "%RUNTIME%" equ "d" copy /y ms\nt.mak ms\nt.mak.unhacked
if "%RUNTIME%" equ "d" perl -p -e "s/\/MT/\/MD/g" ms\nt.mak.unhacked > ms\nt.mak

nmake -f ms\nt.mak
nmake -f ms\nt.mak install
copy /y tmp32\lib.pdb %~dp0\%PLATFORM%-m%RUNTIME%\lib\
nmake -f ms\nt.mak clean

::
:: Debug
::

perl Configure debug-%CONFIGURE% no-asm --prefix=%~dp0\%PLATFORM%-m%RUNTIME%d
call %SETUP%

if "%RUNTIME%" equ "d" copy /y ms\nt.mak ms\nt.mak.unhacked
if "%RUNTIME%" equ "d" perl -p -e "s/\/MT/\/MD/g" ms\nt.mak.unhacked > ms\nt.mak

nmake -f ms\nt.mak
nmake -f ms\nt.mak install
copy /y tmp32.dbg\lib.pdb %~dp0\%PLATFORM%-m%RUNTIME%d\lib\
nmake -f ms\nt.mak clean

::
:: Restore
::

if "%RUNTIME%" equ "d" copy /y ms\nt.mak.orig ms\nt.mak

::
:: Tidy
::

git checkout .
git clean -fdx

popd

pushd %~dp0

if exist openssl-install attrib -r openssl-install\*.* /s
if exist openssl-install rmdir /s /q openssl-install

ren %PLATFORM%-m%RUNTIME%\lib m%RUNTIME%
ren %PLATFORM%-m%RUNTIME%d\lib m%RUNTIME%d

ren %PLATFORM%-m%RUNTIME% openssl-install
mkdir openssl-install\lib\vstudio-%VisualStudioVersion%\%PLATFORM%
move openssl-install\m%RUNTIME% openssl-install\lib\vstudio-%VisualStudioVersion%\%PLATFORM%\
move %PLATFORM%-m%RUNTIME%d\m%RUNTIME%d openssl-install\lib\vstudio-%VisualStudioVersion%\%PLATFORM%\
rmdir /s /q %PLATFORM%-m%RUNTIME%d

popd

endlocal
