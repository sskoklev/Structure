. .\GlobalRepository.ps1

function get-serviceAccountPassword($username) {
    (get-globalvariable("ServiceAccount\$username")).value
}

function get-domainname {
    (get-globalvariable("Global\DomainFQDN")).value
}

function get-domainshortname {
    (get-globalvariable("Global\DomainNetBIOS")).value
}

function get-Computername([string]$ComponentID,[string]$InstanceID){
    $c = (get-globalvariable("Global\CustomerID")).value

    $l = (get-globalvariable("Global\LocationID")).value
    $name = "$c$($ComponentID)$l$($InstanceID)W"
    $name
}

function Get-CustomerId {
    (get-globalvariable("Global\CustomerID")).value
}

function Get-LocationId {
    (get-globalvariable("Global\LocationID")).value
}

########################################################################################
# Author: Marina Krynina
# $serverShortName is in ComponentId-InstanceId format, e.g. DBS-003
#########################################################################################
function Get-ServerNameFromShortName([string]$serverShortName)
{
    ($componentId, $instanceId) = $serverShortName.Split("-") 
    $servername = (get-Computername $componentId $instanceId)

    return $servername
}

########################################################################################
# Author: Marina Krynina
# $serverShortName is either in ComponentId-InstanceId format, e.g. DBS-003, OR full "normal" computer name
# the script will ping the name and see if is a short name or not
#########################################################################################
function Get-ServerName([string]$serverShortName)
{
    $rv = Test-Connection -ComputerName $serverShortName -Count 2 -ErrorAction SilentlyContinue
        
    if ($rv -eq $null)
    {
        # computer is offline or cannot be contacted. Assuming it is in COMPONENT-INSTANCE format
        $servername = Get-ServerNameFromShortName $serverShortName
    }
    else
    {
        # the ping was successful, the computer is ONLINE
        $servername = $serverShortName
    }

    return $servername
}

########################################################################################
# Disable/Enable SmartScreen
#########################################################################################
function ChangeSmartScreenValue([string] $state)
{
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name SmartScreenEnabled -ErrorAction Stop -Value $State -Force
}

function Disable-SmartScreen()    
{
    log "INFO: About to disable SmartScreen otherwise a prompt is raised."
    ChangeSmartScreenValue "Off"
}

function Enable-SmartScreen()    
{
    log "INFO: About to enable SmartScreen."
    ChangeSmartScreenValue "On"
}
