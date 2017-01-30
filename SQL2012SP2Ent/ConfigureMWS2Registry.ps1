# ConfigureMWSRegistry.ps1

# $MWSREGISTRYXMLFILENAME = '.\Install\MWSRegistry.xml'

#########################################################################
# Author: Stiven Skoklevski,
# Management of custom nodes within the Registry
#########################################################################

. .\FilesUtility.ps1

<#

here are some script fixes

#>

###########################################
# CreateCustomNodes - Create the nodes and default to False
###########################################
function CreateCustomNodes([string] $MWSREGISTRYXMLFILENAME)
{

    if([String]::IsNullOrEmpty($MWSREGISTRYXMLFILENAME))
    {
       log "The MWSREGISTRYXMLFILENAME parameter is null or empty."
       return
    }

    # *** configure and validate existence of input file
    $inputFile = "$scriptPath\$MWSREGISTRYXMLFILENAME"

    if ((CheckFileExists( $inputFile)) -ne $true)
    {
        log "ERROR: $inputFile is missing, users will not be configured."
        return
    }

    log "INFO: ***** Executing $MWSREGISTRYXMLFILENAME ***********************************************************"

    # Get the xml Data
    $xml = [xml](Get-Content $inputFile)

    $nodes = $xml.SelectNodes("//*[@RootLocation]")

    if (([string]::IsNullOrEmpty($nodes)))
    {
        log "No registry settings to configure in: '$inputFile'"
        return
    }

    foreach ($node in $nodes) 
    {
        $RootLocation = $node.attributes['RootLocation'].value
        $CustomNode = $node.attributes['CustomNode'].value
        $CustomNodeDescription = $node.attributes['CustomNodeDescription'].value


        if([String]::IsNullOrEmpty($RootLocation))
        {
            log "WARN: RootLocation is empty."
            return  # if root isnt created successfully then no point in continuing                      
        }
        if([String]::IsNullOrEmpty($CustomNode))
        {
            log "WARN: CustomNode is empty."
            return  # if root isnt created successfully then no point in continuing                      
        }
        if([String]::IsNullOrEmpty($CustomNodeDescription))
        {
            log "WARN: CustomNodeDescription is empty."
            return  # if root isdnt created successfully then no point in continuing                      
        }

        New-Item -Path $RootLocation -Name $customNode -Value $CustomNodeDescription –Force
        log "INFO: Created root node '$customNode' in '$RootLocation' with value '$CustomNodeDescription'."
    }

    $hiveMWS2Location = $RootLocation + '\' + $CustomNode

    $nodes = $xml.SelectNodes("//*[@PropName]")

    foreach ($node in $nodes) 
    {
        $Name = $node.attributes['PropName'].value
        $Type = $node.attributes['PropType'].value
        $Value = $node.attributes['PropValue'].value

        if([String]::IsNullOrEmpty($Name))
        {
            log "WARN: Name is empty."
            return                        
        }
        if([String]::IsNullOrEmpty($Type))
        {
            log "WARN: Type is empty."
            return                        
        }
        if([String]::IsNullOrEmpty($Value))
        {
            log "WARN: Value is empty."
            return                        
        }

        New-ItemProperty -Path $hiveMWS2Location  -Name $Name -PropertyType $Type -Value $Value  –Force
        log "INFO: Created hive property '$Name' in '$hiveMWS2Location' with value '$Value'"
    }

    $customNodes = Get-ItemProperty -Path $hiveMWS2Location 
    log "INFO: The following nodes have been created within '$hiveMWS2Location': $customNodes"
}

###########################################
# GetNodeValue - Get Node value
###########################################

function GetNodeValue([string] $MWSREGISTRYXMLFILENAME, [string]$PropertyName)
{

  if([String]::IsNullOrEmpty($MWSREGISTRYXMLFILENAME))
    {
       log "The MWSREGISTRYXMLFILENAME parameter is null or empty."
       return
    }

    # *** configure and validate existence of input file
    $inputFile = "$scriptPath\$MWSREGISTRYXMLFILENAME"

    if ((CheckFileExists( $inputFile)) -ne $true)
    {
        log "ERROR: $inputFile is missing, users will not be configured."
        return
    }

    log "INFO: ***** Executing $MWSREGISTRYXMLFILENAME ***********************************************************"

    # Get the xml Data
    $xml = [xml](Get-Content $inputFile)

    $nodes = $xml.SelectNodes("//*[@RootLocation]")

    if (([string]::IsNullOrEmpty($nodes)))
    {
        log "No registry settings to configure in: '$inputFile'"
        return
    }

    foreach ($node in $nodes) 
    {
        $RootLocation = $node.attributes['RootLocation'].value
        $CustomNode = $node.attributes['CustomNode'].value

        if([String]::IsNullOrEmpty($RootLocation))
        {
            log "WARN: RootLocation is empty."
            return  # if root isnt created successfully then no point in continuing                      
        }
        if([String]::IsNullOrEmpty($CustomNode))
        {
            log "WARN: CustomNode is empty."
            return  # if root isnt created successfully then no point in continuing                      
        }

        $hiveMWS2Location = $RootLocation + '\' + $CustomNode

        Push-Location
        Set-Location $hiveMWS2Location
        $PropertyValue = Get-ItemProperty . -Name $PropertyName | Select-Object -Property $PropertyName
        Pop-Location

        log "INFO: Value of Property '$PropertyName' in '$hiveMWS2Location' is '$($PropertyValue.$PropertyName)'."
    }

    $customNodes = Get-ItemProperty -Path $hiveMWS2Location 

    log "INFO: The following nodes exist within '$hiveMWS2Location': $customNodes"

    return $PropertyValue.$PropertyName
}

###########################################
# SetNodeValue - Set Node value
###########################################

function SetNodeValue([string] $MWSREGISTRYXMLFILENAME, [string]$PropertyName, [string]$PropertyValue)
{

  if([String]::IsNullOrEmpty($MWSREGISTRYXMLFILENAME))
    {
       log "The MWSREGISTRYXMLFILENAME parameter is null or empty."
       return
    }

    # *** configure and validate existence of input file
    $inputFile = "$scriptPath\$MWSREGISTRYXMLFILENAME"

    if ((CheckFileExists( $inputFile)) -ne $true)
    {
        log "ERROR: $inputFile is missing, users will not be configured."
        return
    }

    log "INFO: ***** Executing $MWSREGISTRYXMLFILENAME ***********************************************************"

    # Get the xml Data
    $xml = [xml](Get-Content $inputFile)

    $nodes = $xml.SelectNodes("//*[@RootLocation]")

    if (([string]::IsNullOrEmpty($nodes)))
    {
        log "No registry settings to configure in: '$inputFile'"
        return
    }

    foreach ($node in $nodes) 
    {
        $RootLocation = $node.attributes['RootLocation'].value
        $CustomNode = $node.attributes['CustomNode'].value

        if([String]::IsNullOrEmpty($RootLocation))
        {
            log "WARN: RootLocation is empty."
            return  # if root isnt created successfully then no point in continuing                      
        }
        if([String]::IsNullOrEmpty($CustomNode))
        {
            log "WARN: CustomNode is empty."
            return  # if root isnt created successfully then no point in continuing                      
        }

        $hiveMWS2Location = $RootLocation + '\' + $CustomNode

        Push-Location
        Set-Location $hiveMWS2Location
        Set-ItemProperty . -Name $PropertyName -Value $PropertyValue
        Pop-Location

        log "INFO: Value of Property '$PropertyName' in '$hiveMWS2Location' was set to '$PropertyValue'."
    }

    $customNodes = Get-ItemProperty -Path $hiveMWS2Location 

    log "INFO: The following nodes exist within '$hiveMWS2Location': $customNodes"
}
