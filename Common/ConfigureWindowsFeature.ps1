# ConfigureWindowsFeature.ps1
#########################################################################
# Author: Stiven Skoklevski, CSC
# Install a Windows Feature
#########################################################################

. .\FilesUtility.ps1

#########################################################################
# Install a Windows Feature
#########################################################################
function InstallFeature([string]$featurename)
{
    $exists = Get-WindowsFeature | Where {$_.Installed -eq "True" -and $_.Name -eq $featurename }
    if($exists -eq $null)
    {
        $date = Get-Date -Format yyyyMMddHHmmss
        $logfilename = "Logs\Install-$featurename-$date.log"
        Install-WindowsFeature -Name $featurename -IncludeManagementTools -LogPath $logfilename
    }
    else
    {
        log "$featurename is already installed and will not be re-installed."
    }
}

#########################################################################
# Main
#########################################################################

if([String]::IsNullOrEmpty($WINDOWSFEATUREXMLFILENAME))
{
   log "The XMLFILENAME parameter is null or empty."
}
else
{
    # *** configure and validate existence of input file
    $inputFile = "$scriptPath\$WINDOWSFEATUREXMLFILENAME"

    if ((CheckFileExists( $inputFile)) -ne $true)
    {
        log "ERROR: $inputFile is missing, Windows Features will not be configured."
        return
    }

    try
    {
       log "INFO: ***** Executing $inputFile ***********************************************************"

        # Get the xml Data
        $xml = [xml](Get-Content $inputFile)

        $nodes = $xml.SelectNodes("//*[@FeatureName]")

        if (([string]::IsNullOrEmpty($nodes)))
        {
            log "No windows features to configure in: '$inputFile'"
            return
        }

        foreach ($node in $nodes) 
        {
            $feature = $node.attributes['FeatureName'].value
            if(![String]::IsNullOrEmpty($feature))
            {            
                InstallFeature $feature
            }

        }
    }
    catch
    {
        log "Error: Configuring Windows Feature Exception Message: $($_.Exception.Message)"
    }
}


