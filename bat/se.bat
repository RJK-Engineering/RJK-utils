@echo off

REM switch between working dirs scripts/workspace

SET _dir1=%cd:~0,10%
SET _dir2=%cd:~0,12%
SET _subdirs1=%cd:~11%
SET _subdirs2=%cd:~13%

if /i "%_dir1%"=="c:\scripts" cd "c:\workspace\%_subdirs1%"
if /i "%_dir2%"=="c:\workspace" cd "c:\scripts\%_subdirs2%"
