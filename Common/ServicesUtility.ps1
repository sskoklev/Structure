####################### 
##Stop single Service## 
#######################
function Stop-Service([string] $serviceName, $timeout = '00:02:00')
{
    $svc = Get-Service -Name $serviceName -ErrorAction Stop
    If($svc.Status -eq "Stopped") 
    {
        log "INFO: $serviceName service is already stopped" 
    }
    else
    {
        log "INFO: Disabling $serviceName service" 
        Set-Service -Name $serviceName -StartupType Disabled
        log "INFO: Disabled $serviceName service" 

        log "INFO: Stopping $serviceName service" 
        $svc = get-service $serviceName -ErrorAction Stop 
        $svc.stop() 

        log ("INFO: timeout = " + $timeout)
        $svc.WaitForStatus("Stopped", $timeout) 

        log "INFO: Stopped $serviceName service"  
    }
}

################## 
##Start single Service## 
################## 
function Start-Service([string] $serviceName, $timeout = '00:02:00')
{
    $svc = Get-Service -Name $serviceName -ErrorAction Stop
        
    If($svc.Status -eq "Running") 
    {
        log "INFO: $serviceName service is already started" 
    }
    else
    {
        log "INFO: Enabling $serviceName service " 
        Set-Service -Name $serviceName -StartupType Automatic
        log "INFO: Enabled $serviceName service" 


        log "INFO: Starting $serviceName service" 
        $svc = get-service $serviceName -ErrorAction Stop
        $svc.start() 

        log ("INFO: timeout = " + $timeout)
        $svc.WaitForStatus("Running", $timeout)

        log "INFO: Started $serviceName service" 
    }
}

####################### 
##Stop Other Services## 
####################### 
function Stop-Services([string] $services)
{
    log "INFO: Services to stop: $services" 

    $services.Split(",") |  foreach {
        $serviceName = $_

        Stop-Service $serviceName

    }
 }

################## 
##Start Services## 
################## 
function Start-Services([string] $services)
{
    log "INFO: Services to start: $services" 

    $services.Split(",") |  foreach {
        $serviceName = $_

        Start-Service $serviceName

    }
}


################## 
##Start Services Start Timeout##
################## 
function Set-ServiceStartTimeout ($timeout)
{
    [string] $regKeyName = "HKLM:\SYSTEM\CurrentControlSet\Control"
    [string] $name = "ServicesPipeTimeout"

    $to = (Get-Item -Path $regKeyName).GetValue($name)
    
    If (!($to))
    {
        log "INFO: Creating $regKeyName\$name"
        New-ItemProperty -Path "$regKeyName" -Name $name -PropertyType DWORD -Value $timeout -ErrorAction SilentlyContinue | Out-Null
        log "INFO: Created $regKeyName\$name"
    }
    else
    {
        log "INFO: $regKeyName\$name already exists and is set to $to"
    }

}