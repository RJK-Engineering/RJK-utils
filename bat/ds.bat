@cd\
@set RJK_UTIL=system\drivestatus\drivestatus.pl
@set RJK_UTIL_NOPAUSE=1
@call rjk-util --start ^
--poke-interval 20 ^
--status-file "%LOCALAPPDATA%\.disks.status" ^
--window-title "%~n0" %*
