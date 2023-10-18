:: Creates Aminet package
::
:: Asks for author and uploader information during this process

@ECHO OFF

SET deploy_path=%~dp0deploy

SET author=%1
SET uploader=%2

SET author_uploader_check_regex=^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6} \([A-Z][a-z]+( [A-Za-z])*\)$

:AUTHOR_REQUEST
IF "%author%"=="" SET /P author=Enter Aminet author information! 

ECHO %author%|FINDSTR /r "%author_uploader_check_regex%"
IF ERRORLEVEL 1 (
  ECHO Not a valid author information! It should look like "mmustermann@example.com (Max Mustermann)"
  SET author=
)
IF "%author%"=="" goto :AUTHOR_REQUEST

:UPLOADER_REQUEST
IF "%uploader%"=="" SET /P uploader=Enter Aminet uploader information 
IF "%uploader%"=="" SET uploader=%author%
ECHO %uploader%|FINDSTR /r "%author_uploader_check_regex%"
IF ERRORLEVEL 1 (
  ECHO Not a valid uploader information! It should look like "mmustermann@example.com (Max Mustermann)"
  SET uploader=
)
IF "%uploader%"==""  goto :UPLOADER_REQUEST

MKDIR "%deploy_path%" >NUL:
IF NOT EXIST "%deploy_path%" EXIT /b 10
DEL "%deploy_path%\sysvars.lha" >NUL:

:UNIQUE_TMP_DIR_NAME
SET "tmp_dir=%TMP%\sysvars_tmp_%RANDOM%"
if EXIST "%tmp_dir%" goto :uniqLoop
MKDIR "%tmp_dir%\source" >NUL: || EXIT /b 10
ECHO Working in temporary directory "%tmp_dir%"
PUSHD "%tmp_dir%"

ROBOCOPY "%~dp0..\source" "source" /MIR
IF %ERRORLEVEL% GEQ 8 THEN GOTO :END

ECHO Assembling...
"vasmm68k_mot" -m68000 -kick1hunks -chklabels -Fhunk -nosym -wfail -warncomm -x "source\sysvars.s" -o sysvars.o || GOTO :END
ECHO Linking...
"vlink" -b amigahunk -B static sysvars.o -o sysvars || GOTO :END
DEL sysvars.o

ECHO Generating readme...
powershell -Command "(gc '%~dp0sysvars.readme') -replace '\$author\$', '%author%' -replace '\$uploader\$', '%uploader%' | Out-File -encoding ASCII sysvars.readme" || GOTO :END

COPY sysvars.readme "%deploy_path%" || GOTO :END
ECHO LHA Crunching...
lha a -o7 "%deploy_path%\sysvars.lha" sysvars sysvars.readme source || GOTO :END

:END
POPD
RMDIR /s /q "%tmp_dir%"
EXIT /b 10