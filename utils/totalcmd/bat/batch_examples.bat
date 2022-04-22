:: LIST SOURCE

:: File
batch /L=File                   -- cmd/d/c @echo "%~F"
:: Clipboard
batch /C                        -- cmd/d/c @echo "%~F"
:: First and only line in deref.me, deref.me otherwise
batch /L=deref.me               -- cmd/d/c @echo "%~F"
:: Prevent deref
batch /L=dont.deref.me /noderef -- cmd/d/c @echo "%~F"
:: Dereferenced list must have extension tmp (default=txt)
batch /L=deref.me /E=tmp        -- cmd/d/c @echo "%~F"
:: Current working directory
batch /D                        -- cmd/d/c @echo "%~F"
:: Current working directory, names only
batch /N                        -- cmd/d/c @echo "%~F"
:: Current working directory and subdirs
batch /S                        -- cmd/d/c @echo "%~F"
:: Directory c:\temp
batch /dir=c:\temp              -- cmd/d/c @echo "%~F"
:: Directory c:\temp, names only
batch /dir=c:\temp /N           -- cmd/d/c @echo "%~F"
:: Directory c:\temp and subdirs
batch /dir=c:\temp /S           -- cmd/d/c @echo "%~F"
