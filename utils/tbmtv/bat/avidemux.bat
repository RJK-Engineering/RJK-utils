rem Get format from file extension
set format=Mkv
if /i "%~x1"==".flv" set format=Mp4v2
if /i "%~x1"==".mp4" set format=Mp4v2
if /i "%~x1"==".avi" set format=Avi

rem Get format from filename: filename contains "x265"
set name=%~n1
if not "%name%"=="%name:x265=%" set format=Mkv

rem Get format from directory name: file is in dir named "mkv"
for /f "delims=" %%P in ("%~dp1.") do set dirname=%%~nP
if /i "%dirname%"=="mkv" set format=Mkv

rem Get format from AVIDEMUX_OUTPUT_FORMAT environment variable
if defined AVIDEMUX_OUTPUT_FORMAT if not "%AVIDEMUX_OUTPUT_FORMAT%"=="0" set format=%AVIDEMUX_OUTPUT_FORMAT%

start /b avidemux.exe --force-alt-h264 --load %1 --output-format %format%
