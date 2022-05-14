@echo off
setlocal

set name=%1
set value=%2
set rate=

if /i "%name%"=="CLEAR" goto CLEAR_PRESETS
if /i "%name%"=="CREATE" goto CREATE_PRESETS
if /i "%name%"=="SET" goto SET_RATE
if defined value goto SET_PRESET_VALUE
if defined name goto SELECT_PRESET
goto HELP

:SET_RATE
set rate=%value%
echo rate=%rate%
call :set-rate
if %ERRORLEVEL% neq 0 exit/b
endlocal & set KEYBOARD_CHAR_REPEAT_CURR_RATE=%rate%
exit/b

:SET_PRESET_VALUE
if "%~2"=="" (
    reg delete HKCU\Environment /v KEYBOARD_CHAR_REPEAT_PRESET_%name%
) else (
    set rate=%value%
    call :set-preset
)
goto END

:SELECT_PRESET
call set rate=%%KEYBOARD_CHAR_REPEAT_PRESET_%name%%%
if not defined rate (
    call :get-rate
) else (
    echo %name%=%rate%
)
if defined rate call :set-rate
goto END

:HELP
echo USAGE:
echo.
echo Set rate:
echo     %~n0 SET [keyboard rate]
echo Select preset (prompt for new preset if preset does not exist):
echo     %~n0 [preset name]
echo Set preset:
echo     %~n0 [preset name] [keyboard rate]
echo Delete preset:
echo     %~n0 [preset name] ""
echo.
echo Keyboard rate range: 1-31
echo.
echo Stored presets:
FOR /F "tokens=1,2 delims==" %%F IN ('set KEYBOARD_CHAR_REPEAT_PRESET_') DO call :show-preset %%F %%G
echo.
echo Current rate: %KEYBOARD_CHAR_REPEAT_CURR_RATE%
exit/b 1

:CLEAR_PRESETS
endlocal
FOR /F "tokens=1,2" %%F IN ('reg query HKCU\Environment /v KEYBOARD_CHAR_REPEAT_PRESET_*') DO (
    if "%%G"=="REG_SZ" (
        echo delete %%F
        set %%F=
        reg delete HKCU\Environment /v %%F /f
    )
)
exit/b

:CREATE_PRESETS
endlocal
call rateswitch MIN=1
call rateswitch LOWER=2
call rateswitch LO=5
call rateswitch MEDLO=8
call rateswitch MED=10
call rateswitch MEDHI=12
call rateswitch HI=15
call rateswitch HIGHER=20
call rateswitch MAX=31
exit/b

:set-rate
    mode con rate=%rate% delay=1
    if %ERRORLEVEL% neq 0 exit/b
    set KEYBOARD_CHAR_REPEAT_CURR_RATE=%rate%
    setx KEYBOARD_CHAR_REPEAT_CURR_RATE %rate% >NUL
exit/b

:get-rate
    set/p rate=%name%=
    if defined rate call :set-preset
exit/b

:set-preset
    call :set-rate
    if %ERRORLEVEL% neq 0 exit /b
    echo set KEYBOARD_CHAR_REPEAT_PRESET_%name%=%rate%
    setx KEYBOARD_CHAR_REPEAT_PRESET_%name% %rate%
exit/b

:show-preset
    set key=%1
    set key=%key:KEYBOARD_CHAR_REPEAT_PRESET_=%
    echo %key%=%2
exit/b

:END
if %ERRORLEVEL% equ 0 endlocal & (
    set KEYBOARD_CHAR_REPEAT_PRESET_%name%=%rate%
    set KEYBOARD_CHAR_REPEAT_CURR_RATE=%KEYBOARD_CHAR_REPEAT_CURR_RATE%
)
