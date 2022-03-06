@echo off

set name=%1
set value=%2
if not defined name goto HELP

set cur_rate=%KEYBOARD_CHAR_REPEAT_CURR_RATE%
set def_rate=%KEYBOARD_CHAR_REPEAT_DEFAULT_RATE%
if not defined def_rate set def_rate=31

set rate=
if defined value (
    set rate=%value%
    call set KEYBOARD_CHAR_REPEAT_PRESET_%name%=%value%
    call setx KEYBOARD_CHAR_REPEAT_PRESET_%name% %value% >NUL
) else if defined switch (
    if not "%cur_rate%"=="%def_rate%" set rate=%def_rate%
)

if not defined rate call set rate=%%KEYBOARD_CHAR_REPEAT_PRESET_%name%%%
if not defined rate (
    echo KEYBOARD_CHAR_REPEAT_PRESET_%name% not defined.
    set ERRORLEVEL=1
    goto END
)

:SET_RATE
echo rate=%rate%
mode con rate=%rate% delay=1
set KEYBOARD_CHAR_REPEAT_CURR_RATE=%rate%
setx KEYBOARD_CHAR_REPEAT_CURR_RATE %rate% >NUL
goto END

:HELP
echo USAGE: %~n0 [preset name] [value]
echo.
echo Keyboard rate value range: 1-31
echo.
echo Stored presets:
set | find "KEYBOARD_CHAR_REPEAT_PRESET_"
set ERRORLEVEL=2

:END
if %ERRORLEVEL% GTR 0 pause
