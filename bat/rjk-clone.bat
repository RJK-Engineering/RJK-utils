@echo off

if "%~1" == "" (
    echo Clone repository, default user=%USER%
    echo USAGE: %0 [repo] [user] [git clone options]
    EXIT/B
)
set REPO=%1
set USER=RJK-Engineering

echo on
git clone https://www.github.com/%USER%/%REPO%.git %2 %3 %4 %5 %6 %7 %8 %9
