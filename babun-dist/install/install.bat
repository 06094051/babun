@echo off
setlocal enableextensions enabledelayedexpansion

set SCRIPT_PATH=%~dp0
set SCRIPT_PATH=%SCRIPT_PATH:\=/%
set CUSTOM=false
set INSTALLER_PATH=
set BABUN_ZIP=%SCRIPT_PATH%/dist/babun.zip
set UNZIPPER=%SCRIPT_PATH%/dist/unzip.exe
set LOG_FILE=%SCRIPT_PATH%/installer.log

set SETPATH_SCRIPT=%BABUN_HOME%\tools\setpath.vbs
set LINK_SCRIPT=%BABUN_HOME%\tools\link.vbs
set FREESPACE_SCRIPT=C:\Users\Soham\babun\babun-dist\tools\freespace.vbs

ECHO [babun] Installing babun

if %1.==. (
	set BABUN_HOME=%USERPROFILE%\.babun
	set TARGET=%USERPROFILE%
	GOTO CHECKTARGET
)	
if "%1"=="/t" GOTO TARGET
if "%1"=="/target" (GOTO TARGET || GOTO UNKNOWNFLAG)

:UNKNOWNFLAG
ECHO [babun] Unknown flag provided. Terminating!
pause
EXIT /b 255

:TARGET
if %2.==. GOTO NOTARGET
set BABUN_HOME=%~2\.babun
set TARGET=%~2
set CUSTOM=true
ECHO [babun] Installing to: "%BABUN_HOME%"
GOTO CHECKTARGET

:NOTARGET
ECHO [babun] Target flag set but no target provided:
ECHO [babun] install.bat /target "D:\target_folder"
ECHO [babun] Retry with a target specified. Terminating!
pause
EXIT /b 255

:CHECKTARGET
set /a count=0
for %%x in (%BABUN_HOME%) do set /a count+=1
if %count% gtr 1 (
	ECHO [babun] ERROR: Destination directory contains spaces or illegal characters
	ECHO [babun] %BABUN_HOME%
	ECHO [babun] Please use another destination with the command:
	ECHO [babun] install.bat /target "D:\target_folder"
	ECHO [babun] Retry with a different target. Terminating!
	pause
	EXIT /b 255
)

:CHECKFREESPACE	
set DRIVE_LETTER=%BABUN_HOME:~0,2%
FOR /F "usebackq tokens=*" %%r in (`cscript //Nologo "%FREESPACE_SCRIPT%" "%DRIVE_LETTER%"`) DO SET FREE_SPACE=%%r
if %FREE_SPACE% lss 1024 (
	ECHO [babun] ERROR: There is not enough space on your destination drive %DRIVE_LETTER%
	ECHO [babun] Babun requires at least 1024 MB to operate properly
	ECHO [babun] Free Space on %DRIVE_LETTER% %FREE_SPACE% MB
	ECHO [babun] Please install babun to another destination using the /target option:
	ECHO [babun] install.bat /target "D:\target_folder"
	pause	
	EXIT /b 255
)

:UNZIP
set CYGWIN_HOME=%BABUN_HOME%\cygwin

if exist "%BABUN_HOME%/*.*" (
 	ECHO [babun] Babun home already exists: %BABUN_HOME%"
	ECHO [babun] Delete the old folder in order to proceed. Terminating!
	pause
 	EXIT /b 255
)
if not exist "%BABUN_HOME%" (mkdir "%BABUN_HOME%" || goto :ERROR)
if "%CUSTOM%"=="true" ECHO %BABUN_HOME%>%BABUN_HOME%\custom_install.config
ECHO [babun] Unzipping 

"%UNZIPPER%" "%BABUN_ZIP%" -d "%TARGET%"
if not exist "%BABUN_HOME%/*.*" (GOTO ERROR)

:POSTINSTALL
ECHO [babun] Running post-installation scripts. It may take a while...
%CYGWIN_HOME%\bin\dash.exe -c "/usr/bin/rebaseall" || goto :ERROR
%CYGWIN_HOME%\bin\bash.exe --norc --noprofile -c "/usr/local/etc/babun/source/babun-core/tools/post_extract.sh" || goto :ERROR
rem execute any command with -l (login) to run the post-installation scripts
%CYGWIN_HOME%\bin\bash.exe -l -c "date; rm -rf /usr/local/etc/babun/stamps/check; rm -rf /usr/local/etc/babun/stamps/welcome;" || goto :ERROR

:PATH
ECHO [babun] Adding babun to the system PATH variable
if not exist "%SETPATH_SCRIPT%" (
    ECHO [babun] ERROR: Cannot add babun to the system PATH variable. Script not found!
)
cscript //Nologo "%SETPATH_SCRIPT%" "%BABUN_HOME%"

:LINK
if exist "%USERPROFILE%\Desktop\babun.lnk" (
    ECHO [babun] Deleting old desktop link
    DEL /F /Q "%USERPROFILE%\Desktop\babun.lnk"
)
ECHO [babun] Creating a desktop link
if not exist "%LINK_SCRIPT%" (
    ECHO [babun] ERROR: Cannot create a desktop link. Script not found!
)
cscript //Nologo "%LINK_SCRIPT%" "%USERPROFILE%\Desktop\babun.lnk" "%BABUN_HOME%\babun.bat"

:INSTALLED
ECHO [babun] Babun installed successfully. You can delete the installer now.
ECHO [babun] Enjoy! @tombujok

:RUN
ECHO [babun] Starting babun
%BABUN_HOME%\babun.bat || goto :ERROR
GOTO END

:ERROR
ECHO [babun] Terminating due to internal error #%errorlevel%
EXIT /b %errorlevel%

:END 
pause
