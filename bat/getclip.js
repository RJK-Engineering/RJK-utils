text = WSH.CreateObject('htmlfile').parentWindow.clipboardData.getData('text');
if (text != null) WSH.Echo(text);
