exit/b
rem Command line versions!
rem In a bat file "%%" should be used instead of a single "%".

run /prompt "question:" -- cmd/d/c @echo answer: %~I

rem supported choices: 0..9
run /O 1="option 1" /O 2="option 2" -- cmd/d/c @echo %~O
run /O 1="option 1" /O 2="option 2" /OM="a message:" -- cmd/d/c @echo choice: %~O

run -- cmd/d/c @echo 1st line on clipboard: %L
