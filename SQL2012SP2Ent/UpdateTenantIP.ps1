#########################################################################
# Author: Stiven Skoklevski, CSC
# Find and replace the IP addresses with the tenant specific Production IPs
# USed to replace IP addresses
#
# Assumption is that the initial VPN has a prefix of 10.5.7.
#
#########################################################################

function UpdateIP()
{
    # configuration files only reside in the following folders and file types
    $files = Get-ChildItem -Path "$($scriptPath)\Config", "$($scriptPath)\Install", "$($scriptPath)\ConfigFiles"  -Include "*.ps1", "*.ini", "*.xml" -Recurse

    foreach ($file in $files)
    {
        $findStringExists = (Get-Content $file.PSPath) | Select-String $findString
        if($findStringExists -ne $null)
        {
            (Get-Content $file.PSPath) | 
                Foreach-Object {$_ -replace $findString, $replaceString} | 
                Set-Content $file.PSPath 
        
            log "INFO: Replaced $findString with $replaceString in $($file.PSPath)"
        }
    }
}

#########################################################################
# Main
#########################################################################

Set-Location -Path $scriptPath 
$scriptName = $MyInvocation.MyCommand.Name

. .\LoggingV3.ps1 $true $scriptPath $scriptName

if([String]::IsNullOrEmpty($TENANTIPPREFIX))
{
   log "ERROR: The TENANTIPPREFIX parameter is null or empty."
   return 1
}

# edit the strings below accordingly
# $replaceString = "10.2.20."
$replaceString = $TENANTIPPREFIX

# the lines below this comment should not be updated
$findString = "10.5.7."
$scriptPath = split-path -Parent $MyInvocation.MyCommand.Definition

log "INFO: Updating '$findstring' with '$replaceString'"

UpdateIP
