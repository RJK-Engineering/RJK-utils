IF not defined cmessage SET cmessage=?
CHOICE /C %choices% /N /M %cmessage%
CALL SET value=%%choice_%errorlevel%%%
FOR /F "tokens=*" %%O IN (""%value%"") DO SET args=%args%
