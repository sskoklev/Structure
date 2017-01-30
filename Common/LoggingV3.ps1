#########################################################################
# Author: Marina Krynina, CSC
# Updates:
#         2014-11-12 Added header block
#                    Added echo in the log function
#         2015-01-22 Replaced "echo" with Write-Host as "echo" pollutes return codes
#         2015-03-10 Put test around log folder create (rsparkes)
#########################################################################

#########################################################################
# Set log file name: yyyyMMdd-HHmmss-ScriptName-log.txt
# If ScriptName contains spaces, they are removed: 20121811-1109-45-InstallSQL-log.txt
#
# Create log folder: CurrentScriptLocation\Logs
#########################################################################
Param(
    [Parameter(Mandatory=$false)]
    [bool]$newVersion = $false,
    [Parameter(Mandatory=$false)]
    [string]$scriptPath = $env:USERPROFILE,
    [Parameter(Mandatory=$false)]
    [string]$scriptName = $MyInvocation.PSCommandPath
)

function ConfigureLogging([string] $scriptPath, [string] $fullScriptName)
{
    Write-Host "Start ConfigureLogging: $fullScriptName"
    # set log file name
    $date = get-date -Format "yyyyMMdd-HHmmss"
    $scriptName = ($fullScriptName.Replace(" ", "")).Replace(".ps1", "")
    
    # create Logs folder if it doesn't exist
    $logfileFolder = "$scriptPath\Logs"

    # set full logfile name
    $global:logfile = "$logfileFolder\$date-$scriptName-log.txt"
    $global:errorfile = "$logfileFolder\ERROR-$date-$scriptName.txt"
    Write-Host "Current log file: $global:logfile"
    Write-Host "Current error file: $global:errorfile"

    if(!(Test-Path -Path $logfileFolder))
    {
        $NewLogFolder = New-Item -Path $logfileFolder -Type Directory
        If ($NewLogFolder -ne $Null) {
            Write-Host "Created folder $logfileFolder"
        }
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
        if ($logdata.ToUpper().Contains("ERROR"))
        {
            Write-Output  "$date - $logdata" | Out-File $global:errorfile -Append   
            Write-Host "$date - $logdata"
        }
        else
        {
            Write-Output  "$date - $logdata" | Out-File $global:logfile -Append   
            Write-Host "$date - $logdata"
        }

        return
    }
    catch [Exception]
    {
        Write-Host $_.Exception | format-list -force
        throw
    }
}
#########################################################################
# Main
#########################################################################

if($newVersion -eq $true)
{
    $filename = [System.IO.Path]::GetFileNameWithoutExtension($scriptName)
    ConfigureLogging $scriptPath $filename
}
