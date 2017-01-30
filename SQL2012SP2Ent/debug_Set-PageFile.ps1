# get current script location
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptName = $MyInvocation.MyCommand.Name

. .\Logging.ps1 $true $scriptPath $scriptName

$PAGEFILEPATH = 'F:\pagefile.sys'
$INITIALSIZEMB = 48000
$MAXIMUMSIZEMB = 48000

. .\Set-PageFile.ps1