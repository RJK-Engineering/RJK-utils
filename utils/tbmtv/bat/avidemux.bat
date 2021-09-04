rem Get format from filename: filename contains "x265"
set name=%~n1
if not "%name%"=="%name:x265=%" set format=Mkv& goto GO

rem Get format from directory name: file is in dir named "mkv"
for /f "delims=" %%P in ("%~dp1.") do set dirname=%%~nP
if /i "%dirname%"=="mkv" set format=Mkv& goto GO

rem Get format from file extension
call set format=%%AVIDEMUX_OUTPUT_FORMAT%~x1%%
if defined format goto GO

if /i "%~x1"==".flv" set format=Mp4v2& goto GO
if /i "%~x1"==".mp4" set format=Mp4v2& goto GO
if /i "%~x1"==".avi" set format=Avi& goto GO

rem Default format
set format=%AVIDEMUX_OUTPUT_FORMAT%
if not defined format set format=Mkv

:GO
start /b avidemux.exe --force-alt-h264 --load "%~f1" --output-format %format%
