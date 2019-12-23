@echo off
if "%~1" == "" echo Clone RJK repository & echo USAGE: %0 [repo] & goto END
set REPO=%1
set USER=RJK-Engineering
git clone %3 %4 %5 https://www.github.com/%USER%/%REPO%.git
:END

