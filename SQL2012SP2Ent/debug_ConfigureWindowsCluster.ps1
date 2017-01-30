# get current script location
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptName = $MyInvocation.MyCommand.Name

. .\LoggingV2.ps1 $true $scriptPath $scriptName

$SHAREDWINDOWSCLUSTERXMLFILENAME = 'Install\Cluster\WindowsClusterSharedDB.xml'
$MWSREGISTRYXMLFILENAME = 'Install\MWSRegistry.xml'

. .\ConfigureWindowsCluster.ps1 $scriptPath $SHAREDWINDOWSCLUSTERXMLFILENAME $MWSREGISTRYXMLFILENAME "DEMO3\agilitydeploy"

