rem append first arg to second arg
if not "%~2"=="" type %1 >> %2

rem COPY appends an extra character..: 0x1a
rem COPY /A /Y %2+%1 %2

if %errorlevel% GTR 0 pause
