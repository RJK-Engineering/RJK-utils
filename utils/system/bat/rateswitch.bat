@echo off

echo rate=0-31

set rate=%1
if "%1"=="" set rate=5

set default_rate=%2
if "%2"=="" set default_rate=31
if "%KEYBOARD_CHAR_REPEAT_RATE%"=="" set KEYBOARD_CHAR_REPEAT_RATE=%default_rate%

if "%KEYBOARD_CHAR_REPEAT_RATE%"=="%default_rate%" (
    set KEYBOARD_CHAR_REPEAT_RATE=%rate%
    setx KEYBOARD_CHAR_REPEAT_RATE %rate% >NUL
) else (
    set KEYBOARD_CHAR_REPEAT_RATE=%default_rate%
    setx KEYBOARD_CHAR_REPEAT_RATE %default_rate% >NUL
)

echo rate=%KEYBOARD_CHAR_REPEAT_RATE% delay=1
mode con rate=%KEYBOARD_CHAR_REPEAT_RATE% delay=1
