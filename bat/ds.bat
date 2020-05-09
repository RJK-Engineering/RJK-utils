@cd\
@call rjk-util system\drivestatus\drivestatus.pl /n --start ^
--poke-interval 20 ^
--status-file "%LOCALAPPDATA%\.disks.status" ^
--window-title "%~n0" %*
