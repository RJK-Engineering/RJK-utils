setlocal
set env-var-name=%1
set key=%2
set value=
call :traverse %%%env-var-name%%%
endlocal & set -hash-value=%value%
exit/b

:traverse
:next
set value=%2
if not defined value exit/b
if /i "%1"=="%key%" exit/b
shift & shift
goto next
