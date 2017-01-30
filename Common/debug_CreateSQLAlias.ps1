# Author: Marina Krynina
#################################################################################################

try
{
    # get current script location
    $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
    $scriptName = $MyInvocation.MyCommand.Name

    $SQLASLIAS_XML = "\ConfigFiles\AW-SqlAlias.xml"
    if ([string]::IsNullOrEmpty($SQLASLIAS_XML))
    { 
        $SQLASLIAS_XML = "ConfigFiles\AW-SqlAlias.xml"
    }

    . .\LoggingV2.ps1 $true $scriptPath "Execute-CreateSQLAlias.ps1"
    . .\Execute-CreateSQLAlias.ps1 $scriptPath
    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    log "ERROR: Exception occurred `nException Message: $ex"

    exit 1
} 
