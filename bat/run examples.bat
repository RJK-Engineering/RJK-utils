exit/b

rem supported choices: 0..9
run /O 1="option 1" /O 2="option 2" /OM="a message" -- cmd/d/c @echo %~O
