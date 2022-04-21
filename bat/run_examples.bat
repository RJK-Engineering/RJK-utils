:: USER INPUT (NOTE: DOSKEY macros are in effect!)

:: Replace %I with user input
run /prompt "question:"                               -- cmd/d/c @echo answer: %~I
:: Default value
run /prompt "question:" /defaultvalue="default value" -- cmd/d/c @echo answer: %~I
:: Replace %O with user choice
:: Supported choices: 0..9
run /O 1="choice 1" /O 2="choice 2"                  -- cmd/d/c @echo choice: %~O
run /O 1="choice 1" /O 2="choice 2" /OM="a message:" -- cmd/d/c @echo choice: %~O

:: CLIPBOARD

:: Replace %L with first line on clipboard
run -- cmd/d/c @echo 1st line on clipboard: %L
:: Replace %C with path to file containing clipboard text
run type %C

:: FILE LISTS

:: Replace %D with file list of cwd
run type %D
:: Replace %N with file list of cwd, file names only
run type %N
:: Replace %S with file list of cwd and subdirs recursively
run type %S
:: List of c:\temp instead of cwd
run /list=c:\temp type %D
run /list=c:\temp type %N
run /list=c:\temp type %S

:: Append file list from clipboard if no args after /C?
run type /C?
run type /C? file
:: Append file list of cwd
run type /D?
:: Append file list of cwd, file names only
run type /N?
:: Append file list of cwd and subdirs recursively
run type /S?
:: Append file list of c:\temp instead of cwd
run type /d?=c:\temp
run type /n?=c:\temp
run type /s?=c:\temp

:: LOGGING

:: Set log file
set COMMANDER_RUN_LOG=path-to-file
:: Show log file path
echo %COMMANDER_RUN_LOG%
:: Disable logging
set COMMANDER_RUN_LOG=
:: Disable logging temporarily
run /nolog dir/w
:: Display entire log file
run /showlog
:: Delete log file (prompts for confirmation)
run /clearlog

:: OTHER

:: Disable parameter substitution
run /noparams -- cmd /d/c @echo %L
