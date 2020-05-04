@cd\
@set RJK_UTIL_NOPAUSE=1
@call rjk-util system\drivestatus\drivestatus.pl --start ^
--poke-interval 20 ^
--status-file "%LOCALAPPDATA%\.disks.status" ^
--window-title "%~n0" %*
