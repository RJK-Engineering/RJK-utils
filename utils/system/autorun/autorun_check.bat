SET installed=
FOR /F "tokens=1,3" %%F IN ('reg query "HKCU\Software\Microsoft\Command Processor" /v "AutoRun"') do (
    IF "%%F"=="AutoRun" (
        SET installed=%%G
    )
)
