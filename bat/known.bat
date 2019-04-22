@echo off

call "%~dp0..\config.bat"

perl "%rjk-utils-home%\emule\known\known.pl" -l ^
--db-host "%known-db-host%" ^
--db-user "%known-db-user%" ^
--db-pass "%known-db-pass%" ^
--db-name "%known-db-name%" %*
