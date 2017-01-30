# get current script location
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptName = $MyInvocation.MyCommand.Name

. .\LoggingV2.ps1 $true $scriptPath $scriptName

$XMLFILENAME = 'Install\Cluster\SharedDiskConfigSharedDB.xml'
$MWSREGISTRYXMLFILENAME = 'Install\MWSRegistry.xml'


$NUMBERSHAREDDISKS = '7'

. .\ConfigureSharedDisks.ps1


