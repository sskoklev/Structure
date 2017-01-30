# get current script location
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptName = $MyInvocation.MyCommand.Name

. .\LoggingV2.ps1 $true $scriptPath $scriptName

$CLUSTERNAMES = "CLN-996;CLN-997;CLN-998;CLN-999;CLN-999"
$CLUSTERNAMES = "CLN-996"

. .\ExecuteCreateClusterADObjects.ps1 $scriptPath $CLUSTERNAMES 