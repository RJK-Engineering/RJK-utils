@echo off

choice /m "Remove empty directories recursively"
if %errorlevel% neq 1 exit/b

dir/ad/b/s %1 >%TEMP%\%~n0.dirtree
perl -e "open F, '%TEMP%\%~n0.dirtree';print reverse(<F>)" >%TEMP%\%~n0.dirtree2
FOR /F "delims=" %%F IN (%TEMP%\%~n0.dirtree2) DO rd "%%F" 2>NUL

del %TEMP%\%~n0.dirtree
del %TEMP%\%~n0.dirtree2
