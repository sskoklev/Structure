#########################################################################
# Author: Marina Krynina, CSC
# Updates:
#         2014-11-12 Added new functions DeployAppFiles, Extract
#########################################################################

#########################################################################
# Create backup copy of a file
#########################################################################
function CreateBackupCopy([string] $fileLocation)
{
    log "INFO: Creating a backup copy of original file"
    $date = get-date -Format "yyyyMMdd-HHmmss"
    Copy-Item $fileLocation -destination "$fileLocation.$date"
}

#########################################################################
# Replace placeholder with actual value
#########################################################################
function ReplacePlaceholderWithValue ([string] $fileLocation, [string] $placeholder, [string] $value)
{
    if (($fileLocation -ne $null) -and ($fileLocation -ne ""))
    {
        log  "INFO: ReplacePlaceholderWithValue::Checking if $fileLocation exists"
        if(-not (Test-Path -Path "$fileLocation"))
        {
	        log  "WARNING: Cannot find file :$fileLocation. Exiting the function." 
	        return
        }


        log "INFO: Replacing $placeholder with $value in $fileLocation"
  
        (Get-Content "$fileLocation") | Foreach-Object {$_ -replace $placeholder,$value }  | Out-File "$fileLocation" -Force
    }
}

###############################################################################################
# Update xml file and save content in a new file
###############################################################################################
function Update-ConfigXML([string]$key, [string] $value, [string]$sourceCfgFile, [string]$targetCfgFile)
{
     if ( !([string]::IsNullOrEmpty($value)) ) 
    {
        log "INFO: Setting $key value to $value"
        ( Get-Content -Path "$targetCfgFile" ) | Foreach-Object {$_ -replace "<$key Value=.*", "<$key Value=""$value"" />"} | Set-Content -Path $targetCfgFile
    }
    else
    {
        log "INFO: $key variable is not set. Using value from $targetCfgFile"
    }
}

###############################################################################################
# Update attribute in a xml file and save content in a new file
###############################################################################################
function Update-XMLAttribute([string]$key, [string]$item, [string] $value, [string]$targetCfgFile)
{
    if ( !([string]::IsNullOrEmpty($value)) ) 
    {
        log "INFO: Setting $key/$item value to $value"
        # ( Get-Content -Path "$sourceCfgFile" ) | Foreach-Object {$_ -replace "<$key $nodeName=.*", "<$key $nodeName=""$value"" "} | Set-Content -Path $targetCfgFile
        [xml]$xml = (Get-Content $targetCfgFile)

        $node = $xml.SelectSingleNode($key)
        if ($node -ne $null)
        {
            $attr = $node.GetAttribute($item)
            if ($attr -ne $null)
            {
                $node.SetAttribute($item, $value)
                $xml.Save($targetCfgFile)
            }
            else
            {
            log "WARNING: Attribute $item is not found in the $targetCfgFile."
            }

        }
        else
        {
            log "WARNING: Node $key is not found in the $targetCfgFile."
        }
    }
    else
    {
        log "INFO: $key/$item variable is not set. Using value from $targetCfgFile"
    }
}
###############################################################################################
# Update INI file
###############################################################################################
function Update-IniFile([string] $filelocation, [string]$node, [string]$value)
{
    if ($value -eq $null -or $value -eq "")
    {
        log "INFO: $node value is 0 length, assuming default defined in the INI file"
        return
    }

    log "INFO: Updating $node with $value in $fileLocation"

    (Get-Content $fileLocation) -replace "$node=.*", ("$node=" + '"' + $value + '"') | Set-Content $fileLocation

}

########################################################################################################
# Check if file exists
########################################################################################################
function CheckFileExists([string] $fileLocation)
{
    # Check if XML file exists
    if ( !([string]::IsNullOrEmpty($fileLocation)))
    {
        log  "INFO: Checking if '$fileLocation' exists"
        if(-not (Test-Path -Path "$fileLocation" -PathType Leaf))
        {
	        log  "INFO: Cannot find file: '$fileLocation'. Exiting the function." 
	        return $false
        }
        else
        {
            return $true
        }
    }
    else
    {
	        log  "WARNING: fileLocation is null or empty. Exiting the function." 
	        return $false
    }
}

########################################################################################################
# Check if folder exists
########################################################################################################
function CheckFolderExists([string] $fileLocation)
{
    # Check if XML file exists
    if ( !([string]::IsNullOrEmpty($fileLocation)))
    {
        log  "INFO: Checking if '$fileLocation' exists"
        if(-not (Test-Path -Path "$fileLocation" -PathType Container))
        {
	        log  "INFO: Cannot find folder: '$fileLocation'. Exiting the function." 
	        return $false
        }
        else
        {
            return $true
        }
    }
    else
    {
	        log  "WARNING: fileLocation is null or empty. Exiting the function." 
	        return $false
    }
}

########################################################################################################
# DEPRECATED - DO NOT USE
# Use the functions CheckFolderExists or CheckFileExists instead. 
# Check if file exists
########################################################################################################
function IfFileExists([string] $fileLocation)
{
    # Check if XML file exists
    if (($fileLocation -ne $null) -and ($fileLocation -ne ""))
    {
        log  "INFO: Checking if $fileLocation exists"
        if(-not (Test-Path -Path "$fileLocation"))
        {
	        log  "INFO: Cannot find file:$fileLocation. Exiting the function." 
	        return $false
        }
        else
        {
            return $true
        }
    }
    else
    {
	        log  "WARNING: fileLocation is null or empty. Exiting the function." 
	        return $false
    }
}

########################################################################################################
# Extracts ALL iso and zip files found in the media source folder and sub-folders
########################################################################################################
function Extract([string] $extractionTool, [string] $installMediaFolder)
{
    # Extract installation media
    # TODO: check if files, folders exist

    # find all zip, iso files in \SP folder including subfolders and extract them into location they are found
    (Get-ChildItem -Path $installMediaFolder -Recurse –File | Where-Object {($_.Extension -eq ".iso") -or ($_.Extension -eq ".zip")}) | `
     Foreach-Object {    
        $installationPackage = $_.FullName
        $location = $_.DirectoryName

        log "INFO: $installationPackage will be extracted into $location"
        if ((IfFileExists $extractionTool) -eq $true)
        {
            LaunchProcessAsCurrentUser $extractionTool "x $installationPackage -aos -r -y -o$location"
        }
        else
        {
            throw "ERROR: $extractionTool is missing"
        }
     }    
}

########################################################################################################
# Extracts iso/zip file
########################################################################################################
function ExtractFile([string] $extractionTool, [string]$installMediaSource, [string] $installMediaFile)
{
    (Get-ChildItem -Path $installMediaSource -Recurse –File | Where-Object {($_.Name -eq $installMediaFile)}) | `
     Foreach-Object {    
        $installationPackage = $_.FullName
        $location = $_.DirectoryName

        log "INFO: $installationPackage will be extracted into $location"
        if ((IfFileExists $extractionTool) -eq $true)
        {
            LaunchProcessAsCurrentUser $extractionTool "x $installationPackage -aos -r -y -o$location"
        }
        else
        {
            throw "ERROR: $extractionTool is missing"
        }
     }    
}

########################################################################################################
# Gets attribute value from xml node
########################################################################################################
Function GetFromNode([System.Xml.XmlElement]$node, [string] $item)
{
    $value = $node.GetAttribute($item)
    If ($value -eq "")
    {
        $child = $node.SelectSingleNode($item);
        If ($child -ne $null)
        {
            Return $child.InnerText;
        }
    }
    Return $value;
}
