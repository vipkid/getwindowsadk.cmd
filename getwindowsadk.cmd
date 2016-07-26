REM getwindowsadk.cmd
REM Copyright (C) 2016 lea2000
REM 
REM This program is free software: you can redistribute it and/or modify  
REM it under the terms of the GNU General Public License as published by  
REM the Free Software Foundation, version 3.
REM 
REM This program is distributed in the hope that it will be useful, but 
REM WITHOUT ANY WARRANTY; without even the implied warranty of 
REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
REM General Public License for more details.
REM 
REM You should have received a copy of the GNU General Public License 
REM along with this program. If not, see <http://www.gnu.org/licenses/>.

@echo off
cls
setlocal EnableDelayedExpansion

REM SETTINGS START

REM Everything will be copied to this location.
REM Directory will be removed, before and afterwards
set workdir=%SYSTEMDRIVE%\adksetup

REM Download adksetup.exe and missing packages
set downloadmissingpackages=True

REM Define which features should be installed
set features=
REM set features=!features! OptionId.ApplicationCompatibilityToolkit
set features=!features! OptionId.DeploymentTools
set features=!features! OptionId.WindowsPreinstallationEnvironment
REM set features=!features! OptionId.ImagingAndConfigurationDesigner
REM set features=!features! OptionId.UserStateMigrationTool
REM set features=!features! OptionId.VolumeActivationManagementTool
REM set features=!features! OptionId.WindowsPerformanceToolkit
REM set features=!features! OptionId.WindowsAssessmentToolkit
REM set features=!features! OptionId.WindowsAssessmentServicesClient
REM set features=!features! OptionId.SqlExpress2012
REM set features=!features! OptionId.WindowsAssessmentServices

REM SETTINGS END

net session >nul 2>&1
if not !ERRORLEVEL!==0 (
	echo Error - this command prompt is not elevated
	goto end
)

set bitsadmin_exe=%SYSTEMROOT%\System32\bitsadmin.exe
set url=http://download.microsoft.com/download/3/8/B/38BBCA6A-ADC9-4245-BCD8-DAA136F63C8B/adk/adksetup.exe

set currentdir=%~dp0

set links=!currentdir!LINKS.txt
for %%f in ("!url!") do set filename=%%~nxf
set filename_ap=!currentdir!!filename!

set layoutlog=%TEMP%\!filename!_layout.log
set insstalllog=%TEMP%\!filename!_install.log

:deleteold

if exist "!workdir!" (

	echo|set /p=Deleting old work dir ... 
	rmdir /s /q "!workdir!" >nul 2>&1
	set exitcode=!ERRORLEVEL!
	if not exist "!workdir!" set exitcode=0
	echo !exitcode!
	
	If not !exitcode!==0 (
		echo Error deleting old work dir
		goto end
	)
)

taskkill /f /im !filename! >nul 2>&1
if !ERRORLEVEL!==0 echo Killed remaining !filename! processes

md "!workdir!" >nul 2>&1

:copycache
if not exist "!currentdir!Installers" goto download

echo|set /p=Copying current dir to work dir... 
xcopy "!currentdir!Installers" "!workdir!\Installers" /eiy >nul 2>&1
set exitcode=!ERRORLEVEL!
echo !exitcode!

If not !exitcode!==0 (
	echo Error Copying current dir to work dir
	goto end
)
	
:download
If not "!downloadmissingpackages!"=="True" goto install

If exist "!filename_ap!" del /f /q "!filename_ap!" >nul 2>&1

ping -n 1 google.com 2>&1 | find "TTL" >nul 2>&1
if !ERRORLEVEL!==0 (

	echo|set /p=Downloading !filename!... 
	"!bitsadmin_exe!" /Transfer "bitsjob_%RANDOM%" "!url!" "!workdir!\!filename!" >nul 2>&1
	set exitcode=!ERRORLEVEL!
	echo !exitcode!

	if not !exitcode!==0 (
		del /f /q "!workdir!\!filename!" >nul 2>&1
		echo Error downloading !filename!
		goto end
	)
	
	copy /y "!workdir!\!filename!" "!filename_ap!" >nul 2>&1
	
) else (
	echo Error Can't download !filename! - no internet connection?
	goto end
)

If not exist "!workdir!\!filename!" (
	echo !workdir!\!filename! not found
	goto end
)

if exist "!layoutlog!" del /f /q "!layoutlog!" >nul 2>&1

echo|set /p=Downloading missing packages... 
"!workdir!\!filename!" /layout "!workdir!" /log "!layoutlog!" /quiet
set exitcode=!ERRORLEVEL!
echo !exitcode!

If not !exitcode!==0 (
	echo Error downloading missing packages
	goto end
)

:backupcache

echo|set /p=Backing up packages to current dir ...
xcopy "!workdir!\Installers" "!currentdir!Installers"  /eiy >nul 2>&1
set exitcode=!ERRORLEVEL!
echo !exitcode!

:install

If not exist "!workdir!\Installers" (
	echo Error Package cache not found in work dir
	goto end
)
If not exist "!workdir!\!filename!" (
	If not exist "!filename_ap!" (
		echo Error !filename_ap! not found
		goto end
	)	
	copy "!filename_ap!" "!workdir!\!filename!" >nul 2>&1
)

echo|set /p=Installing!features!... 
"!workdir!\!filename!" /features!features! /log "!insstalllog!" /ceip off /quiet /norestart
set exitcode=!ERRORLEVEL!
echo !exitcode!

If not !exitcode!==0 (
	echo Error installing DeploymentTools and WindowsPreinstallationEnvironment
	goto end
)

:end

taskkill /f /im !filename! >nul 2>&1
if !ERRORLEVEL!==0 echo Killed remaining !filename! processes
taskkill /f /im !filename! >nul 2>&1
if !ERRORLEVEL!==0 echo Killed remaining !filename! processes
timeout /t 5 >nul 2>&1

echo|set /p=Deleting work dir ... 
rmdir /s /q "!workdir!" >nul 2>&1
set exitcode=!ERRORLEVEL!
if not exist "!workdir!" set exitcode=0
echo !exitcode!

pause
exit !exitcode!
