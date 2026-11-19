@echo off
title Build PC-Hardware-Inspector
set "HERE=%~dp0"
set "ROOT="
if exist "%HERE%Icon\PHI.ico" set "ROOT=%HERE%"
if not defined ROOT if exist "%HERE%..\Icon\PHI.ico" set "ROOT=%HERE%..\"
if not defined ROOT if exist "%HERE%..\..\Icon\PHI.ico" set "ROOT=%HERE%..\..\"

set "SRC=%HERE%Launcher.cs"
if not exist "%SRC%" set "SRC=%HERE%Engine\Launcher.cs"
if not exist "%SRC%" goto nosrc

set "CSC=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if not exist "%CSC%" set "CSC=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if not exist "%CSC%" goto nocsc

set "OUT=%HERE%PC-Hardware-Inspector.exe"
if defined ROOT set "OUT=%ROOT%PC-Hardware-Inspector.exe"

if defined ROOT goto withicon
echo Icon\PHI.ico not found. Building without an icon.
"%CSC%" /nologo /target:exe /optimize+ /out:"%OUT%" "%SRC%"
goto done

:withicon
"%CSC%" /nologo /target:exe /optimize+ /out:"%OUT%" /win32icon:"%ROOT%Icon\PHI.ico" "%SRC%"

:done
if errorlevel 1 goto failed
echo.
echo Done. Created: %OUT%
pause
exit /b 0

:nosrc
echo Could not find Launcher.cs next to this file.
pause
exit /b 1

:nocsc
echo Could not find the C# compiler.
pause
exit /b 1

:failed
echo Build failed.
pause
exit /b 1
