#########################################################################
# Author: Marina Krynina, CSC
# Updates:
#         2014-11-12 Added header block
#                    Added echo in the log function
#         2015-01-22 Replaced "echo" with Write-Host as "echo" pollutes return codes
#########################################################################

#########################################################################
# Set log file name: yyyyMMdd-HHmmss-ScriptName-log.txt
# If ScriptName contains spaces, they are removed: 20121811-1109-45-InstallSQL-log.txt
#
# Create log folder: CurrentScriptLocation\Logs
#########################################################################
function ConfigureLogging([string] $scriptPath, [string] $fullScriptName)
{
    echo "Start ConfigureLogging: $fullScriptName"
    # set log file name
    $date = get-date -Format "yyyyMMdd-HHmmss"
    $scriptName = ($fullScriptName.Replace(" ", "")).Replace(".ps1", "")
    
    # create Logs folder if it doesn't exist
    $logfileFolder = "$scriptPath\Logs"

    # set full logfile name
    $script:logfile = "$logfileFolder\$date-$scriptName-log.txt"
    echo "Current log file: $script:logfile"

    if(!(Test-Path -Path $logfileFolder))
    {
        New-Item -Path $logfileFolder -Type Directory
        log "Created folder $logfileFolder"
    }

    return
}


#########################################################################
# Write log
#########################################################################
function log ([string]$logdata)
{
    $date = get-date
    try
    {
        Write-Output  "$date - $logdata" | Out-File $script:logfile -Append   
        Write-Host "$date - $logdata"
        return
    }
    catch [Exception]
    {
        Write-Host $_.Exception | format-list -force
        throw
    }
}