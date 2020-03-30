@echo off

set USER=RJK-Engineering

if "%~1" == "" echo Clone repository, default user=%USER% & echo USAGE: %0 [repo] [user] [git clone options] & goto END

set REPO=%1
if not "%~2" == "" set USER=%2

echo on
git clone https://www.github.com/%USER%/%REPO%.git %3 %4 %5
:END

