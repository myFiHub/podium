@echo off
rem This file was created by pub v2.19.6.
rem Package: get_cli
rem Version: 1.8.4
rem Executable: getx
rem Script: get
if exist "C:\Users\mohsen\AppData\Local\Pub\Cache\global_packages\get_cli\bin\get.dart-2.19.6.snapshot"                                                                                                                                                                         (
  call dart "C:\Users\mohsen\AppData\Local\Pub\Cache\global_packages\get_cli\bin\get.dart-2.19.6.snapshot"                                                                                                                                                                         %*
  rem The VM exits with code 253 if the snapshot version is out-of-date.
  rem If it is, we need to delete it and run "pub global" manually.
  if not errorlevel 253 (
    goto error
  )
  call dart pub global run get_cli:get %*
) else (
  call dart pub global run get_cli:get %*
)
goto eof
:error
exit /b %errorlevel%
:eof
