#########################################################################
# Author: Marina Krynina, Stiven Skoklevski, CSC
# Find and replace the a given substring with a new value
#########################################################################

function UpdateConfigFiles([string]$inputFile)
{
   [xml]$xmlinput = (Get-Content $inputFile)

   [string]$folders = $xmlinput.Update.Folder

   $nodes = $xmlinput.SelectNodes("//Update/Item")
    if (([string]::IsNullOrEmpty($nodes)))
    {
        log "INFO: No nodes configured in: '$inputFile'"
        return 0
    }

    foreach($folder in $folders)
    {
        # configuration files only reside in the following folders and file types
        $path = "$scriptPath\$folder\*"
        $files = Get-ChildItem -Path "$path" -Include "*.xml", "*.ini"

        foreach ($file in $files)
        {
            foreach ($node in $nodes) 
            {
                [string]$findString = $node.attributes['OldValue'].value
                [string]$replaceString = $node.attributes['NewValue'].value
        
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
    }
}

#########################################################################
# Main
#########################################################################
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptName = $MyInvocation.MyCommand.Name

. .\LoggingV3.ps1 $true $scriptPath $scriptName
. .\FilesUtility.ps1

$replaceData_XML = "$scriptPath\_admin_ReplaceValuesInConfigFiles.xml"

if ((CheckFileExists($replaceData_XML )) -eq $false)
{
    throw "ERROR: $replaceData_XML is specified but missing"
}

UpdateConfigFiles $replaceData_XML
