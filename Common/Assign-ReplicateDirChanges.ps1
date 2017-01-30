Param(
    [string] $scriptPath,
    [string] $identity
)

#################################################################################################
# Author: Marina Krynina
# Desc:   Assigns an account replicate directory changes permission in AD
#         This is required by SharePoint 2013 to support User profiles synchronisation
#################################################################################################
Set-Location -Path $scriptPath 

. .\PlatformUtils.ps1
. .\LoggingV2.ps1 $true $scriptPath "Assign-ReplicateDirChanges.ps1"

try
{

    [string]$domainFQDN = get-domainname
    [string]$domainNetBIOS = get-domainshortname
    log "INFO: fqdn = $domainFQDN, netBIOS = $domainNetBIOS" 

    $RootDSE = [ADSI]"LDAP://RootDSE"
    $DefaultNamingContext = $RootDse.defaultNamingContext
    $ConfigurationNamingContext = $RootDse.configurationNamingContext
    log "INFO: Getting user principal for $identity"
    $UserPrincipal = New-Object Security.Principal.NTAccount("$identity")

    log "INFO: Assigning $identity Replicate Directory Changes permission on Default naming context $DefaultNamingContext"
    DSACLS "$DefaultNamingContext" /G "$($UserPrincipal):CA;Replicating Directory Changes"

    if ($domainFQDN.ToUpper().Contains($domainNetBIOS.ToUpper()) -ne $true)
    {
        log "WARNING: $domainFQDN is different from $domainNetBIOS. No configuration of the COnfiguration naming context has been done."
        # MK: this was NOT tested
        # log "INFO: Assigning $identity Replicate Directory Changes permission on Configuration naming context $ConfigurationNamingContext"
        # DSACLS "$ConfigurationNamlolingContext" /G "$($UserPrincipal):CA;Replicating Directory Changes"
    }

    return 0
}
catch
{
    log "ERROR: $($_.Exception.Message)"
    throw "ERROR: $($_.Exception.Message)"
}