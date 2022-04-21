exit/b
rem Command line versions!
rem In a bat file "%%" should be used instead of a single "%".


rem User input

rem Replace %I with user input
run /prompt "question:"                               -- cmd/d/c @echo answer: %~I
rem Default value
run /prompt "question:" /defaultvalue="default value" -- cmd/d/c @echo answer: %~I
rem Replace %O with user choice
rem Supported choices: 0..9
run /O 1="choice 1" /O 2="choice 2"                  -- cmd/d/c @echo choice: %~O
run /O 1="choice 1" /O 2="choice 2" /OM="a message:" -- cmd/d/c @echo choice: %~O


rem Clipboard

rem Replace %L with first line on clipboard
run -- cmd/d/c @echo 1st line on clipboard: %L
rem Replace %C with path to file containing clipboard text
run type %C


rem File lists

rem Replace %D with file list of cwd
run type %D
rem Replace %N with file list of cwd, file names only
run type %N
rem Replace %S with file list of cwd and subdirs recursively
run type %S
rem List of c:\temp instead of cwd
run /list=c:\temp type %D
run /list=c:\temp type %N
run /list=c:\temp type %S

rem Append file list from clipboard if no args after /C?
run type /C?
run type /C? file
rem List of cwd
run type /D?
rem List of cwd, file names only
run type /N?
rem List of cwd and subdirs recursively
run type /S?


rem Logging

run /nolog dir/w
run /showlog
run /clearlog


rem Other

rem Disable parameter substitution
run /noparams -- cmd /d/c @echo %L

/d?
/n?
/s?
/k
/z
/p
/i
/x
/t
/q
/e
/r
/c
/g
/o
/f
/a
/b
