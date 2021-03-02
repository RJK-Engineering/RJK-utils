set format=Mkv
if /i "%~x1"==".flv" set format=Mp4v2
if /i "%~x1"==".mp4" set format=Mp4v2
if /i "%~x1"==".avi" set format=Avi

set name=%~n1
if not "%name%"=="%name:x265=%" set format=Mkv

for /f "delims=" %%P in ("%~dp1.") do set dirname=%%~nP
if "%dirname%"=="mkv" set format=Mkv

start /b avidemux.exe --force-alt-h264 --load %1 --output-format %format%
