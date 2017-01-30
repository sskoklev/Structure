Param(
    [string] $scriptPath,
    [string] $patchLocation,
    [string] $patches
)



function Stop-Services()
{

    ####################### 
    ##Stop Other Services## 
    ####################### 
    Set-Service -Name "IISADMIN" -startuptype Disabled 
    log "INFO: Gracefully stopping IIS W3WP Processes" 

    iisreset -stop -noforce 

    log "INFO: Services are Stopped" 

 }

function Install-Update([string] $cuSource, [string] $cuName)
{
    ################## 
    ##Start patching## 
    ################## 
    log "INFO: Installing update $cuName" 

    $process = "$cuSource\$cuName"
    $argument = "/passive"

    $domain = get-domainshortname
    $domainFull = get-domainname
    $user = (Get-VariableValue $ADMIN "agilitydeploy" $true)
    $password = get-serviceAccountPassword -username $user

    log "INFO: Calling $process under identity $domain\$user"
    log "INFO: Arguments $argument"
    $Result = LaunchProcessWithHighestPrivAsUser $process $argument "$domain\$user" $password

    log "INFO: Installation complete with return code $Result" 
}

function Start-Services()
{
    ################## 
    ##Start Services## 
    ################## 
    log "INFO: Starting Services Backup"

    Set-Service -Name "IISADMIN" -startuptype Automatic

    $srv3 = get-service "IISADMIN" 
    $srv3.start() 

    log "INFO: Services are Started"
}


############################################################################################
# Main
############################################################################################
# Load Common functions
. .\FilesUtility.ps1
. .\PlatformUtils.ps1
. .\VariableUtility.ps1
. .\LaunchProcess.ps1

Set-Location -Path $scriptPath 
 
 # Logging must be configured here. otherwise it gets lost in the nested calls# 
 . .\LoggingV2.ps1 $true $scriptPath "Install-WAC2013Update.ps1"

# Folder structure on VM
# C:\Users\InstallerAccount
#		\InstallMedia = $INSTALL_MEDIA - the content of the isntall media will be extracted here
#           \MWSUpdates - location of the update that needs to be slipstreamed

log "INFO: Installing an update"

try
{

    log "INFO: Getting all specified files in $patchLocation"
    $patchesArray = $patches -split ","
    $updates = (Get-ChildItem -Path "$patchLocation" -Name -Include $patchesArray -ErrorAction SilentlyContinue) 

    Stop-Services
 
    ForEach ($update in $updates)
    {

        ########################### 
        ##Ensure Patch is Present## 
        ########################### 
        $patchfile = Get-ChildItem -Path "$patchLocation" | where{$_.Name -like $update} 
        if($patchfile -eq $null) 
        { 
          throw "ERROR: Unable to retrieve $patchLocation\$update file.  Exiting Script"     
        }


        Install-Update $patchLocation $update
    }

    Start-Services

    return 0
}
catch
{
    Start-Services

    log "ERROR: $($_.Exception.Message)"

    # This is done to get an error code from the scheduled task.
    Write-Output  $($_.Exception.Message) | Out-File "$scriptPath\error.txt" -Append
    throw "ERROR: $($_.Exception.Message)"
}