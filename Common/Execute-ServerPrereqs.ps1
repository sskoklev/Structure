Param(
    [string] $scriptPath
)

# Author: Marina Krynina

function SetDiskLabels ([xml] $xmlinput)
{
    $startDate = get-date
    $scriptName = "Set-VolumeLabel.ps1"
    $errorFile = "Error-" + $scriptName + "-" + (get-date -Format "yyyyMMdd-HHmmss") + ".txt"

    . .\LoggingV3.ps1 $true $scriptPath $scriptName

    try
    {
        $DISKLABELS = ""
        $nodes = $xmlinput.SelectNodes("//Settings/Volumes/Volume")
        ForEach ($node in $nodes)
        {
            $provision = $node.GetAttribute("Provision")
            $driveLetter = $node.GetAttribute("DriveLetter")
            $name = $node.GetAttribute("Name")

            log "INFO: provision = $provision, driveLetter = $driveLetter, volume name = $name"
            if ($provision -eq "true")
            {
                $DISKLABELS += $driveLetter + ";" + $name + ","
            }
        }

        if ($DISKLABELS -ne "")
        {
            . .\Set-VolumeLabel.ps1
        }
        else
        {
            log "WARNING: DISKLABELS is empty. Disks will NOT be renamed."
        }

        $endDate = get-date
        $ts = New-TimeSpan -Start $startDate -End $endDate
        log "TIME: Processing Time  - $ts"
    }
    catch
    {
        $errorMsg = $($_.Exception.Message)
        log "ERROR: $errorMsg"
        throw "ERROR: $errorMsg "
    }

}

function SetPageFile ([xml] $xmlinput)
{
    $startDate = get-date
    $scriptName = "Set-PageFile.ps1"
    $errorFile = "Error-" + $scriptName + "-" + (get-date -Format "yyyyMMdd-HHmmss") + ".txt"

    . .\LoggingV3.ps1 $true $scriptPath $scriptName

    try
    {
        if ($xmlinput.Settings.PageFile.Provision -eq "true")
        {
            $PAGEFILEPATH = $xmlinput.Settings.PageFile.PageFilePath
            $INITIALSIZEMB = $xmlinput.Settings.PageFile.MaximumSizeMB
            $MAXIMUMSIZEMB = $xmlinput.Settings.PageFile.InitialSizeMB

            log "INFO: About to execute Set-PageFile.ps1"        
            . .\Set-PageFile.ps1
        }
        else
        {
            log "WARNING: PageFile will NOT be set as Provision flag is set to false."
        }

        $endDate = get-date
        $ts = New-TimeSpan -Start $startDate -End $endDate
        log "TIME: Processing Time  - $ts"
    }
    catch
    {
        $errorMsg = $($_.Exception.Message)
        log "ERROR: $errorMsg"
        throw "ERROR: $errorMsg "
    }

}

function ExtractInstallMedia([xml] $xmlinput)
{
    $startDate = get-date
    $scriptName = "Extract-AppFiles.ps1"
    $errorFile = "Error-" + $scriptName + "-" + (get-date -Format "yyyyMMdd-HHmmss") + ".txt"

    . .\LoggingV3.ps1 $true $scriptPath $scriptName

    try
    {

    #################################################
        $nodes = $xmlinput.SelectNodes("//Settings/ExtractFilesSet/ExtractFiles")
        ForEach ($node in $nodes)
        {
            $provision = $node.GetAttribute("Provision")
            $installMedia = ($scriptPath + $node.GetAttribute("InstallMedia"))
            $extractionTool = ($scriptPath + $node.GetAttribute("ExtractionTool"))

            log "INFO: provision = $provision, installmedia = $installMedia, extractionTool = $extractionTool"
            if ($provision -eq "true")
            {
                  Extract $extractionTool $installMedia
            }
            else
            {
                log "WARNING: $installMedia Provision flag is set to false."
            }
        }
    #################################################

        $endDate = get-date
        $ts = New-TimeSpan -Start $startDate -End $endDate
        log "TIME: Processing Time  - $ts"
    }
    catch
    {
        $errorMsg = $($_.Exception.Message)
        log "ERROR: $errorMsg"
        throw "ERROR: $errorMsg"
    }

}

################################################################################################################################################################
Set-Location -Path $scriptPath 

. .\LoggingV3.ps1 $true $scriptPath "Execute-ServerPrereqs.ps1"
. .\FilesUtility.ps1
. .\PlatformUtils.ps1
. .\VariableUtility.ps1
. .\LaunchProcess.ps1

try
{

    $inputFile = Get-VariableValue $COMMONBASESETTINGS_XML "\ConfigFiles\CommonBaseSettings.xml" $true
    $inputFile = ($scriptPath + $inputFile)

    if ((CheckFileExists($inputFile )) -eq $false)
    {
        throw "ERROR: $inputFile is missing"
    }

    # Get the xml Data
    $xmlinput = [xml](Get-Content $inputFile)

    # Volumes
    SetDiskLabels $xmlinput

    # PageFile
    SetPageFile $xmlinput

    #Extracting App Files
    ExtractInstallMedia $xmlinput
}
catch
{
    $errorMsg = $($_.Exception.Message)
    log "ERROR: $errorMsg"
    throw "ERROR: $errorMsg "
}
