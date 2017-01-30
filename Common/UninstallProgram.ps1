# Mandatory heading
#########################################################################
# Author: Stiven Skoklevski, CSC
# Uninstall a program
#########################################################################

function UninstallProgram([string] $appToUninstall)
{

    log "INFO: Uninstall... $appToUninstall 32-bit and 64-bit if they exist"  

    $uninstall32 = gci "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | foreach { gp $_.PSPath } | ? { $_ -match $appToUninstall } | select UninstallString
    $uninstall64 = gci "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | foreach { gp $_.PSPath } | ? { $_ -match $appToUninstall } | select UninstallString

    if ($uninstall64) 
    {
        $uninstall64 = $uninstall64.UninstallString -Replace "msiexec.exe","" -Replace "/I","" -Replace "/X",""
        $uninstall64 = $uninstall64.Trim()
        log "INFO: Uninstalling... $appToUninstall 64-bit"
        start-process "msiexec.exe" -arg "/X $uninstall64 /q" -Wait
        log "INFO: Uninstalled... $appToUninstall 64-bit"  
    }
    else
    {
        log "INFO: Did not find... $appToUninstall 64-bit"  
    }

    if ($uninstall32) 
    {
        $uninstall32 = $uninstall32.UninstallString -Replace "msiexec.exe","" -Replace "/I","" -Replace "/X",""
        $uninstall32 = $uninstall32.Trim()
        log "INFO: Uninstalling.. $appToUninstall 32-bit."
        start-process "msiexec.exe" -arg "/X $uninstall32 /q" -Wait
        log "INFO: Uninstalled... $appToUninstall 32-bit"  
     }
    else
    {
        log "INFO: Did not find... $appToUninstall 32-bit"  
    }
}

