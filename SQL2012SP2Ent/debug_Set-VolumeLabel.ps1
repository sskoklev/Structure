# get current script location
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptName = $MyInvocation.MyCommand.Name

. .\Logging.ps1 $true $scriptPath $scriptName

$DISKLABELS = "E;Application,F;PageFile,"

. .\Set-VolumeLabel.ps1