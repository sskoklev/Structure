Param(
    [string]$scriptPath,
    [string]$domain,
    [string]$SQLUSERSXMLFILE,     # cater for multiple DB servers eg, Shared and SharePoint
    [string]$SQLMEMORYXMLFILE,
    [string]$SQLPORTSXMLFILE,
    [string]$SQLCOMPATIBILITYXMLFILE,
    [string]$GENERICSERVICEXMLFILE
)

############################################################################################
# Author: Stiven Skoklevski
# Desc: Perform post SQL installation configuration tasks   
# Updates: 
############################################################################################

############################################################################################
# Main
############################################################################################

Set-Location -Path $scriptPath 

 # Logging must be configured here. otherwise it gets lost in the nested calls
 . .\LoggingV2.ps1 $true $scriptPath "Configure-SQL.ps1"

 # Load Common functions
. .\FilesUtility.ps1
. .\UsersUtility.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1

try
{

    $msg = "Configuring SQL"
    log "INFO: Starting $msg"
    log "INFO: Getting variables values or setting defaults if the variables are not populated."

    # *** setup account 
    $domain = get-domainshortname
    $user = (Get-VariableValue $ADMIN "agilitydeploy" $true)
    $password = get-serviceAccountPassword -username $user

    log "INFO: ********  Configuring SQL Users  ********"
    . .\Config\Configure-SQLUsers.ps1 -scriptPath $scriptPath -domain $domain -SQLUSERSXMLFILE $SQLUSERSXMLFILE 
    log "INFO: ********  Configured SQL Users  ********"
    
    log "INFO: ********  Configuring SQL Min/Max Memory  ********"
     . .\Config\Configure-SQLMemory.ps1 $scriptPath $SQLMEMORYXMLFILE
    log "INFO: ********  Configured SQL Min/Max Memory  ********"

    log "INFO:"
    log "INFO: ********  Configuring SQL Ports  ********"
    . .\Config\Configure-SQLPort.ps1 -scriptPath $scriptPath -SQLPORTSXMLFILE $SQLPORTSXMLFILE
    log "INFO: ********  Configured SQL Port  ********s"
    
    log "INFO:"
    log "INFO: ********  Configuring SQL Compatibility  ********"
    . .\Config\Configure-SQLPort.ps1 -scriptPath $scriptPath -SQLCOMPATIBILITYXMLFILE $SQLCOMPATIBILITYXMLFILE
    log "INFO: ********  Configured SQL Compatibility  ********s"
        
    log "INFO:"
    log "INFO: ********  Configuring Generic Cluster Services  ********"
    . .\Config\Configure-GenericClusterServices.ps1 -scriptPath $scriptPath -GENERICSERVICEXMLFILE $GENERICSERVICEXMLFILE
    log "INFO: Configured Generic Cluster Services  ********"

    log "INFO: Finished $msg."
    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    log "ERROR: Exception occurred `nException Message: $ex"

    exit 1
}

