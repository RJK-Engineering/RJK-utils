keys = WScript.Arguments(0)
Set WshShell = WScript.CreateObject("WScript.Shell")
WshShell.SendKeys keys
