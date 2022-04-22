IF defined delfilec del/q %delfilec%
IF defined delfiled del/q %delfiled%
IF defined delfilen del/q %delfilen%
IF defined delfiles del/q %delfiles%
IF defined dellistfile del/q %listfile%

IF defined timeout TIMEOUT %timeout%
IF defined pause PAUSE
EXIT/B %exitcode%
