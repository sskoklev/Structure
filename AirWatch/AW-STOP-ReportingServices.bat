powershell.exe -Command Start-Process Powershell.exe -Verb RunAs -ArgumentList "'-NoExit -ExecutionPolicy ByPass -file %~dp0AirWatch-Manage-ReportingService.ps1 -scriptPath %~dp0 -action STOP'" 
