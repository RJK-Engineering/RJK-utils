IF defined defval SET "question=%question% [%defval%]"
SET/P "answer=%question% "
IF not defined answer SET "answer=%defval%"
FOR /F "delims=" %%I IN (""%answer%"") DO SET args=%args%
