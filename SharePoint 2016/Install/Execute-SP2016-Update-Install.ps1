Param(
    [string] $scriptPath
)


#################################################################################################
# Author: Marina Krynina
# Desc:   Functions to support installation of SharePoint updates
#################################################################################################

############################################################################################
# Main
############################################################################################
Set-Location -Path $scriptPath 

# Load Common functions
. .\FilesUtility.ps1
. .\LaunchProcess.ps1
. .\LoggingV3.ps1 $true $scriptPath "Execute-SP2016-Update-Install.ps1"

try
{
    $startDate = get-date
    $msg = "Start installation of SharePoint update(s)"
    log "INFO: Starting $msg"

    if ([string]::IsNullOrEmpty($VARIABLES) -eq $true)
    {
        throw "ERROR: Variable containing name of the Variables script is empty"
    }

    log ("INFO: VARIABLES = " + $VARIABLES)
    . .\$VARIABLES

    $patchLocation = (Join-Path $scriptPath $UPDATES_LOCATION)
    $updatesConfigXml = (Join-Path $scriptPath $UPDATES_XML)

    # check if exists
    if ((CheckFileExists $updatesConfigXml) -ne $true)
    {
        throw "ERROR: config file $updatesConfigXml does not exist in the specified locatioon"
    }

    # read and populate $patches variable
    $xml = [xml](Get-Content $updatesConfigXml)

    $nodes = $xml.SelectNodes("//Updates/Update")

    if (([string]::IsNullOrEmpty($nodes)))
    {
        log "INFO: No updates are configured in: '$updatesConfigXml'"
        return 0
    }

    $patches = ""
    foreach ($node in $nodes) 
    {
        $installFlag = $node.attributes['Install'].value
        $updateName = $node.attributes['Name'].value
        if((![String]::IsNullOrEmpty($installFlag)) -and ($installFlag -eq "true"))
        {            
            $patches += ($updateName + ",")
        }
    }   
      
    log "INFO: Calling Install updates script"
    . .\Install\SP2016-Update-Install.ps1 $scriptPath $patchLocation $patches

    log "INFO: Finished $msg."

    $endDate = get-date
    $ts = New-TimeSpan -Start $startDate -End $endDate
    log "TIME: Processing Time  - $ts"

    return 0
}
catch
{
    throw "ERROR: $($_.Exception.Message)"
}