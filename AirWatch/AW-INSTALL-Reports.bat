powershell.exe -Command Start-Process Powershell.exe -Verb RunAs -ArgumentList "'-NoExit -ExecutionPolicy ByPass -file %~dp0AW-INSTALL-Reports.ps1 -scriptPath %~dp0 '" 
