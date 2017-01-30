# get current script location
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptName = $MyInvocation.MyCommand.Name

. .\LoggingV2.ps1 $true $scriptPath $scriptName

$SQLUSERSXMLFILE = 'config\SQLUsers_SharedDB.xml'
$SQLPORTSXMLFILE = 'config\SQLPorts_SharedDB.xml'
$GENERICSERVICEXMLFILE = 'config\ClusterServices_SharedDB.xml'
$USER = 'agilitydeploy'

# . .\Config\Configure-SQL.ps1
# . .\Config\ExecuteSQLConfiguration.ps1

# . .\install\Configure-WindowsUsers.ps1 $scriptPath $SQLUSERSXMLFILE
. .\ExecuteWindowsUsers.ps1 


