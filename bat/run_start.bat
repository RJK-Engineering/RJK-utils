
SET script=%1
SET arg1=%~2
SET help=
SET error=

IF "%arg1%"=="" (
    SET help=usage
) ELSE IF "%arg1%"=="/?" (
    SET help=extended
) ELSE IF "%arg1%"=="/??" (
    SET help=full
) ELSE IF "%arg1:~0,2%"=="/?" (
    SET help=full
)
