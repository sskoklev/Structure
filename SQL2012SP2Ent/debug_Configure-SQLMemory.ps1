# get current script location
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptName = $MyInvocation.MyCommand.Name

. .\LoggingV2.ps1 $true $scriptPath $scriptName

# Load Common functions
. .\FilesUtility.ps1
. .\UsersUtility.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1

$SQLUSERSXMLFILE = 'config\SQLUsers_SharedDB.xml'
$SQLPORTSXMLFILE = 'config\SQLPorts_SharedDB.xml'
$GENERICSERVICEXMLFILE = 'config\ClusterServices_SharedDB.xml'
$SQLMEMORYXMLFILE = 'config\SQLMemory_SharedDB.xml'
$USER = 'agilitydeploy'

 . .\Config\Configure-SQLMemory.ps1 $scriptPath $SQLMEMORYXMLFILE
#. .\Config\ExecuteSQLConfiguration.ps1


