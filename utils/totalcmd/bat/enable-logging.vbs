If WScript.Arguments.Count() = 0 Then WScript.Quit 1
title = WScript.Arguments(0)

Set WshShell = WScript.CreateObject("WScript.Shell")
WshShell.AppActivate title
WshShell.SendKeys "%oo{END}{UP}{UP}{UP}{UP}%c"
WScript.Sleep(4000)
WshShell.SendKeys "{ENTER}"
