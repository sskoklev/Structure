# get current script location
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptName = $MyInvocation.MyCommand.Name

. .\LoggingV2.ps1 $true $scriptPath $scriptName

$MWSREGISTRYXMLFILENAME = 'Install\MWSRegistry.xml'





. .\ConfigureMWS2Registry.ps1


 CreateCustomNodes $MWSREGISTRYXMLFILENAME

# SetNodeValue $MWSREGISTRYXMLFILENAME 'IsSharedDiskConfigured' 'Blue'
# $value = GetNodeValue $MWSREGISTRYXMLFILENAME 'IsSharedDiskConfigured' 

#Write-Host $value

<# 

    $xml = [xml](Get-Content "C:\Users\skoklevski\Install\MWSRegistry.xml")

ForEach ($line in (Get-Content  "C:\Users\skoklevski\Install\WindowsFeatures.xml")) {
  write-host $line 
}

#>
