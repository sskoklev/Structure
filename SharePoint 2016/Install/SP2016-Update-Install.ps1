Param(
    [string] $scriptPath,
    [string] $patchLocation,
    [string] $patches
)

    $global:srchctr = 1 
    $global:srch4srvctr = 1 
    $global:srch5srvctr = 1

# Author: Marina Krynina
# based on script provided by Russ Maxwell (russmax@microsoft.com)

##################################################################################
function logServiceStatus($services)
{
    foreach($serviceName in $services)
    {
        $srv = get-service $serviceName 
        log ("INFO: service $serviceName, status = " + $srv.status)
    }
}

function Stop-Services-2016()
{
    ######################## 
    ##Stop Search Services## 
    ######################## 
    ##Checking Search services## 
    $global:srchctr = 1 
    $global:srch4srvctr = 1 
    $global:srch5srvctr = 1

    $srv4 = get-service "OSearch16" 
    $srv5 = get-service "SPSearchHostController"

    If(($srv4.status -eq "Running") -or ($srv5.status-eq "Running")) 
      { 
        log "INFO: Search applocation is running. Continuing without pausing the Search Service Application" 
      }

    log "INFO: Stopping Search Services if they are running" 
    if($srv4.status -eq "Running") 
      { 
        $global:srch4srvctr = 2 
        set-service -Name "OSearch16" -startuptype Disabled 
        $srv4.stop() 
      }

    if($srv5.status -eq "Running") 
      { 
        $global:srch5srvctr = 2 
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

function Install-Update-2016([string] $cuSource, [string] $cuName)
{
    ################## 
    ##Start patching## 
    ################## 
    log "INFO: Installing update $cuName" 

    $process = (Join-Path $cuSource $cuName)
    $arguments = "/passive /norestart"

    log "INFO: Calling $process"
    log "INFO: Arguments $argument"

    # LaunchProcessAsAdministrator $process $argument
    Start-Process -FilePath "$process" -ArgumentList $arguments -Wait -NoNewWindow

}

function Start-Services-2016()
{
    ################## 
    ##Start Services## 
    ################## 
    Set-Service -Name "SPTimerV4" -startuptype Automatic 
    Set-Service -Name "IISADMIN" -startuptype Automatic

    $srv2 = get-service "SPTimerV4" 
    if($srv2.status -ne "Running") 
    {
        try
        {
            $srv2.start()
        }
        catch
        {
            Start-Sleep -seconds 10 
            $srv2 = get-service "SPTimerV4" 
            if($srv2.status -ne "Running") 
            {
                $srv2.start()
            }
        }
    }

    $srv3 = get-service "IISADMIN" 
    if($srv3.status -ne "Running") 
      {$srv3.start()}

    $srv4 = get-service "OSearch16" 
    $srv5 = get-service "SPSearchHostController"

    ###Ensuring Search Services were stopped by script before Starting" 
    if($global:srch4srvctr -eq 2) 
    { 
        set-service -Name "OSearch16" -startuptype Automatic 
        if($srv4.status -ne "Running") 
          {$srv4.start()}
    } 
    if($global:srch5srvctr -eq 2) 
    { 
        Set-service "SPSearchHostController" -startuptype Automatic 
        if($srv5.status -ne "Running") 
          {$srv5.start()}
    }
}


function Stop-Services ()
{
        Stop-Services-2016
}

function Start-Services ()
{
        Start-Services-2016
}

############################################################################################
# Main
############################################################################################
Set-Location -Path $scriptPath 

# Load Common functions
. .\FilesUtility.ps1
. .\VariableUtility.ps1
. .\LaunchProcess.ps1
 . .\LoggingV3.ps1 $true $scriptPath "SP2016-Update-Install.ps1"

try
{
    $state = "Off"
    # must be executed as Admin.
    # Turns off Smart screen prompt when install pre-reqs
    log "INFO: Disable SmartScreen otherwise a prompt is raised."
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name SmartScreenEnabled -ErrorAction Stop -Value $State -Force             
    
    log "INFO: Getting all specified files in $patchLocation"
    $patchesArray = $patches -split ","
    if ($patchesArray.Count -ne 0)
    {
        log "INFO: Strat installation of the update(s)"
        log "INFO: attempting to stop windows services"
        $services = @("SPTimerV4", "IISADMIN", "OSearch16", "SPSearchHostController")
        logServiceStatus $services

        log "INFO: Stopping Services"
        Stop-Services 
        logServiceStatus $services
        log "INFO: Stopped Services"
    
        foreach ($p in $patchesArray)
        {
            if (($p -eq $null) -or ($p -eq ""))
            {
                continue
            }

            $updates = (Get-ChildItem -Path "$patchLocation" -Name -Include $p -ErrorAction SilentlyContinue) 
 
            ForEach ($update in $updates)
            {
                $startDate = get-date

                log "INFO: update $update"
                ########################### 
                ##Ensure Patch is Present## 
                ########################### 
                $patchfile = Get-ChildItem -Path "$patchLocation" | where{$_.Name -like $update} 
                if($patchfile -eq $null) 
                { 
                    throw "ERROR: Unable to retrieve $patchLocation\$update file.  Exiting Script"     
                }


                log "INFO: installing $update"
                Install-Update-2016 $patchLocation $update
                log "INFO: installed $update"

                $endDate = get-date
                $ts = New-TimeSpan -Start $startDate -End $endDate
                log "TIME: Processing Time  - $ts"
            }
        }
    
        log "INFO: Starting Services"
        Start-Services 
        logServiceStatus $services
        log "INFO: Started Services"
    }

    return 0
}
catch [Exception]
{
    Start-Services $ver
    logServiceStatus $services

    $ex = $_.Exception | format-list | Out-String
    log "ERROR: Exception occurred `nException Message: $ex"
    throw "ERROR: Exception occurred `nException Message: $ex"
}