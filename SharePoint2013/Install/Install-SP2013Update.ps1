Param(
    [string] $scriptPath,
    [string] $patchLocation,
    [string] $patches,
    [string] $psConfigReqd
)



function Stop-Services()
{
    ######################## 
    ##Stop Search Services## 
    ######################## 
    ##Checking Search services## 
    $srchctr = 1 
    $srch4srvctr = 1 
    $srch5srvctr = 1

    $srv4 = get-service "OSearch15" 
    $srv5 = get-service "SPSearchHostController"

    If(($srv4.status -eq "Running") -or ($srv5.status-eq "Running")) 
      { 
        log "INFO: Search applocation is running. Continuing without pausing the Search Service Application" 
      }

    log "INFO: Stopping Search Services if they are running" 
    if($srv4.status -eq "Running") 
      { 
        $srch4srvctr = 2 
        set-service -Name "OSearch15" -startuptype Disabled 
        $srv4.stop() 
      }

    if($srv5.status -eq "Running") 
      { 
        $srch5srvctr = 2 
        Set-service "SPSearchHostController" -startuptype Disabled 
        $srv5.stop() 
      }

    do 
      { 
        $srv6 = get-service "SPSearchHostController" 
        if($srv6.status -eq "Stopped") 
        { 
            $yes = 1 
        } 
        Start-Sleep -seconds 10 
      } 
      until ($yes -eq 1)

    log "INFO: Search Services are stopped"

    ####################### 
    ##Stop Other Services## 
    ####################### 
    Set-Service -Name "IISADMIN" -startuptype Disabled 
    Set-Service -Name "SPTimerV4" -startuptype Disabled 
    log "INFO: Gracefully stopping IIS W3WP Processes" 

    iisreset -stop -noforce 

    log "INFO: Stopping Services" 

    $srv2 = get-service "SPTimerV4" 
      if($srv2.status -eq "Running") 
      {$srv2.stop()}

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

    #Start-Process $filename $arg

    #Start-Sleep -seconds 20 
    #$proc = get-process $filename 
    #$proc.WaitForExit()

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
    Set-Service -Name "SPTimerV4" -startuptype Automatic 
    Set-Service -Name "IISADMIN" -startuptype Automatic

    ##Grabbing local server and starting services## 
    #$servername = hostname 
    #$server = get-spserver $servername

    $srv2 = get-service "SPTimerV4" 
    $srv2.start() 
    $srv3 = get-service "IISADMIN" 
    $srv3.start() 
    $srv4 = get-service "OSearch15" 
    $srv5 = get-service "SPSearchHostController"

    ###Ensuring Search Services were stopped by script before Starting" 
    if($srch4srvctr -eq 2) 
    { 
        set-service -Name "OSearch15" -startuptype Automatic 
        $srv4.start() 
    } 
    if($srch5srvctr -eq 2) 
    { 
        Set-service "SPSearchHostController" -startuptype Automatic 
        $srv5.start() 
    }

    log "INFO: Services are Started"
}

function Run-PSConfig($psConfigReqd)
{
    if ($psConfigReqd -eq "true")
    {
        log "INFO: Running psconfig"
        iisreset
        Start-Sleep -s 30
        
        psconfig.exe -cmd upgrade -inplace b2b

        # TODO: below is analog of PSCONFIGUI.EXE
        # psconfig.exe -cmd upgrade -inplace b2b -wait -cmd applicationcontent -install -cmd installfeatures -cmd secureresources
    }
    else
    {
        return
    }
}

############################################################################################
# Main
############################################################################################
# Load Common functions
. .\FilesUtility.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1

Set-Location -Path $scriptPath 
 
 # Logging must be configured here. otherwise it gets lost in the nested calls# 
 . .\LoggingV2.ps1 $true $scriptPath "Install-SP2013Update.ps1"

# Folder structure on VM
# C:\Users\InstallerAccount
#		\InstallMedia = $INSTALL_MEDIA - the content of the isntall media will be extracted here
#           \MWSUpdates - location of the update that needs to be slipstreamed

log "INFO: Installing an update"

try
{
    $state = "Off"
    # must be executed as Admin.
    # Turns off Smart screen prompt when install pre-reqs
    log "INFO: Disable SmartScreen otherwise a prompt is raised."
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name SmartScreenEnabled -ErrorAction Stop -Value $State -Force             

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

    Run-PSConfig $psConfigReqd

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