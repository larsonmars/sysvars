:: Creates Aminet package
::
:: You can provide author and uploader information via command line arguments or this script will ask you for it.
@ECHO OFF

SET author=%1
SET uploader=%2

:: You must either have these in %PATH% or you will be asked for their location
SET vasmm68k_mot=vasmm68k_mot
SET vlink=vlink
SET lha=lha

CALL :CHECK_EXE_PATH %vasmm68k_mot%
CALL :CHECK_EXE_PATH %vlink%
CALL :CHECK_EXE_PATH %lha%

SET deploy_path=%~dp0deploy
SET root_path=%~dp0..

:: This regex should match Aminet's requirements of: <e-mail><space><left parenthesis><full name><right parenthesis>
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

MKDIR "%deploy_path%" >NUL 2>&1
IF NOT EXIST "%deploy_path%\" GOTO :ERROR
IF EXIST "%deploy_path%\sysvars.lha" (
  ECHO Deleting old sysvars.lha
  DEL "%deploy_path%\sysvars.lha"
  IF EXIST "%deploy_path%\sysvars.lha" GOTO :ERROR
)
IF EXIST "%deploy_path%\sysvars.readme" (
  ECHO Deleting old sysvars.readme
  DEL "%deploy_path%\sysvars.readme"
  IF EXIST "%deploy_path%\sysvars.readme" GOTO :ERROR
)

:UNIQUE_TMP_DIR_NAME
SET "tmp_dir=%TMP%\sysvars_tmp_%RANDOM%"
if EXIST "%tmp_dir%" goto :uniqLoop
MKDIR "%tmp_dir%" || GOTO :ERROR
ECHO Working in temporary directory "%tmp_dir%"
PUSHD "%tmp_dir%"
MKDIR "sysvars" || GOTO :ERROR
MKDIR "sysvars\source" || GOTO :ERROR

ROBOCOPY "%root_path%\test\sysvars-test" "sysvars" /MIR /xd l c
if errorlevel 8 GOTO :ERROR

COPY "%~dp0dir.info" "sysvars.info" || GOTO :ERROR

ROBOCOPY "%root_path%\source" "sysvars\source" /MIR
if errorlevel 8 GOTO :ERROR

MKDIR "sysvars\c" || GOTO :ERROR

ECHO Assembling...
:: "%vasmm68k_mot%" -m68000 -kick1hunks -chklabels -Fhunk -nosym -wfail -warncomm -x "sysvars\source\sysvars.s" -o sysvars.o || GOTO :ERROR
"%vasmm68k_mot%" -m68000 -kick1hunks -chklabels -Fhunkexe -nosym -wfail -warncomm -x "sysvars\source\sysvars.s" -o sysvars\sysvars || GOTO :ERROR
"%vasmm68k_mot%" -m68000 -kick1hunks -chklabels -Fhunkexe -nosym -wfail -warncomm -x "sysvars\source\ksge36.s" -o sysvars\c\ksge36 || GOTO :ERROR
"%vasmm68k_mot%" -m68000 -kick1hunks -chklabels -Fhunkexe -nosym -wfail -warncomm -x "sysvars\source\probevar.s" -o sysvars\c\probevar || GOTO :ERROR
::ECHO Linking...
::"%vlink%" -b amigahunk -B static sysvars.o -o "sysvars\sysvars" || GOTO :ERROR
::DEL sysvars.o

ECHO Generating readme...
powershell -Command "(gc '%~dp0sysvars.readme') -replace '\$author\$', '%author%' -replace '\$uploader\$', '%uploader%' | Out-File -encoding ASCII 'sysvars\sysvars.readme'" || GOTO :ERROR

COPY "sysvars\sysvars.readme" "%deploy_path%" || GOTO :ERROR

ECHO LHA Crunching...
"%lha%" a -rxo5 "%deploy_path%\sysvars.lha" sysvars sysvars.info || GOTO :ERROR

CALL :CLEANUP
EXIT /b 0

:ERROR
CALL :CLEANUP
ECHO Failed to create Aminet Archive! 1>&2
EXIT /b 10

:: Subroutines

:CLEANUP
ECHO Cleaning up...
IF NOT "%tmp_dir%"=="" (
  POPD
  RMDIR /s /q "%tmp_dir%"
)
EXIT /b 0

:CHECK_EXE_PATH
SET exe_path=%1
:_CHECK_EXE_PATH_LOOP
%exe_path% >NUL 2>&1
IF ERRORLEVEL 9009 (
  SET /P exe_path=Could not find %1 executable... Enter path for %~1! 
  GOTO :_CHECK_EXE_PATH_LOOP
)
SET "%~1=%exe_path%"
EXIT /b 0



