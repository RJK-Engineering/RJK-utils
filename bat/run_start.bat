
SET help=1
SET usage=
SET script=%1

IF "%~2"=="" (
    SET usage=1
) ELSE IF not "%~2"=="/?" (
    SET help=
)
