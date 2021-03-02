@echo off
echo rate=0-31 delay=0-3
set rate=%1
if "%1"=="" set rate=31
set delay=%2
if "%2"=="" set delay=1
echo rate=%rate% delay=%delay%
mode con rate=%rate% delay=%delay%
