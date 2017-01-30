# Mandatory heading
#########################################################################
# Author: Stiven Skoklevski, CSC
# Install SQLServer in a cluster. USed for primary and additional nodes
#########################################################################

# Load Common functions
. .\LaunchProcess.ps1
. .\FilesUtility.ps1
. .\Get-SQLInstance.ps1
. .\Get-IniContent.ps1
. .\GlobalRepository.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1

##########################################################################################################
function UpdateSQLConfigurationFiles([string] $configFile, [hashtable] $parameters)
{    
    # Get the xml Data
    $xml = [xml](Get-Content $configFile)

    $nodes = $xml.SelectNodes("//*[@FullFileName]")
    foreach ($node in $nodes) 
    {
        log  "INFO: ***** Updating $configFile ***********************************************************"
 
        $source = $node.attributes['FullFileName'].value
        $arguments = $node.attributes['CmdLineArgument'].value
        $configFile = $arguments.Replace("/ConfigurationFile=", "")

        log "INFO: Source: $source, Arguments: $arguments, Config File: $configFile."

        log "INFO: Creating backup of $configFile."
        CreateBackupCopy $configFile

        $parameters.GetEnumerator() | % { 
            if($parameters.ContainsKey($($_.key)) -eq $true)
            {
                $foundKey = Select-String -Path $configFile -pattern $($_.key)
                if ( ![string]::IsNullOrEmpty($foundKey) ) 
                {
                    Update-IniFile $configFile $($_.key) $($_.Value)
                }
                else
                {
                    log "INFO: $($_.key) was not found in $configFile."
                }
            }
        }

        UpdateClusterNodeObjects $configFile
    }
}

###########################################################################################
function UpdateClusterNodeObjects([string] $filename)
{
    log "INFO: Replacing short server names in SQL ini file '$filename' with full server names"
    $content = (Get-Content $filename)
    foreach ($line in $content)
    {
        if(($line -match "FAILOVERCLUSTERGROUP") -or ($line -match "FAILOVERCLUSTERNETWORKNAME"))
        {
            $vals = $line -split "="
            $servershortName = $vals[1] -replace '"', ''
            if($servershortName.Length -le 7) # when install is run more than once it will continue to append unless we test here
            { 
               $serverName = ([string](Get-ServerName $servershortName)).ToUpper()

               $newLine = $line -replace $servershortName, $serverName

                (Get-Content $filename) -replace $line, $newLine| Set-Content $filename

                log "INFO: In ini file: '$filename', '$line' was replaced with '$newLine'"
            }

        }

        if($line -match "FAILOVERCLUSTERIPADDRESSES")
        {
            $vals = $line -split "="
            $ips = $vals -split ";"
            $servershortName = $ips[3]
            if($servershortName.Length -le 7) # when install is run more than once it will continue to append unless we test here
            {
                $serverName = ([string](Get-ServerName $servershortName)).ToUpper() 

                $newLine = $line -replace $servershortName, $serverName

                (Get-Content $filename) -replace $line, $newLine| Set-Content $filename
        
                log "INFO: In ini file: '$filename', '$line' was replaced with '$newLine'"
            }
        }
    }
}
 
###########################################################################################
function ExecuteSQLConfigurationFiles([string] $scriptPath, [string] $configFile, [System.Management.Automation.PSCredential] $dcred, [hashtable] $parameters)
{
    # Get list of installed instances. Will skip installation for existing instance
    log "INFO: Getting list of installed instances"
    Get-SQLInstance -ComputerName $env:COMPUTERNAME | ForEach{   
        $list = $list + "|" + $_.SQLInstance.ToUpper()
    }      

    if ($list -eq $null -or $list -eq "")
    {
        log "INFO: No SQL instances currently exist on $env:COMPUTERNAME"
    }
    else
    {
        $list = $list + "|"
        log "INFO: The following SQL instances have already been installed on $env:COMPUTERNAME: $list"
    }

    # Get the xml Data
    $xml = [xml](Get-Content $configFile)

    $nodes = $xml.SelectNodes("//*[@FullFileName]")
    foreach ($node in $nodes) 
    {
        $source = $node.attributes['FullFileName'].value
        $arguments = $node.attributes['CmdLineArgument'].value
        $configFile = $arguments.Replace("/ConfigurationFile=", "")

        log  "INFO: ***** Executing $configFile ***********************************************************"

        # Identify if configured instance is in the list of installed instances
        $FileContent = Get-IniContent $configFile 
        $instance = $FileContent["OPTIONS"]["INSTANCENAME"]
        $action = $FileContent["OPTIONS"]["ACTION"]
        
        # note that values are returned with double quotes
        if($action.ToLower() -eq '"install"')
        {
            log "INFO: Installing (not adding a cluster node) SQL features on instance: '$instance'."

             # Get refreshed list of installed instances. Will skip installation for existing instance
            log "INFO: Getting refreshed list of installed instances"
            Get-SQLInstance -ComputerName $env:COMPUTERNAME | ForEach{   
                $list = $list + "|" + $_.SQLInstance.ToUpper()
            }      

            if ($list -eq $null -or $list -eq "")
            {
                log "INFO: No SQL instances currently exist on $env:COMPUTERNAME"
            }
            else
            {
                $list = $list + "|"
                log "INFO: The following SQL instances have already been installed on $env:COMPUTERNAME: $list"
            }

            if ( ![string]::IsNullOrEmpty($list) ) 
            {
                if (($list.Contains(($instance.ToUpper()).Replace('"', ""))) -ne $true)
                {
                    # instance does not exists, skip installation
                    log  "INFO: $instance does NOT exists. Skipping to the next DB instance."
                    continue
                }
            }

            # configure the command to install the SSRS service only.
            $fullPathArgument = "/ConfigurationFile=$scriptPath\" + $arguments.Replace("/ConfigurationFile=", "") + `
                " /SkipRules=StandaloneInstall_HasClusteredOrPreparedInstanceCheck" + `
                " /Action=Install"
        }
        else
        {
            log  "INFO: $configFile is configured to install $instance instance"

            if ( ![string]::IsNullOrEmpty($list) ) 
            {
                if (($list.Contains(($instance.ToUpper()).Replace('"', ""))) -eq $true)
                {
                    # instance exists, skip installation
                    log  "INFO: $instance exists. Skipping to the next DB instance."
                    continue
                }
            }
    
            $fullPathArgument = "/ConfigurationFile=$scriptPath\" + $arguments.Replace("/ConfigurationFile=", "")
        }

        log "INFO: The full configuration file path is: $fullPathArgument"

        LaunchProcessAsUser "$scriptPath\$source" $fullPathArgument $dcred.GetNetworkCredential().username $dcred.GetNetworkCredential().password

        Start-Sleep -Seconds 15
    }
}

###########################################################################################
# Main
###########################################################################################

$configFile = "$scriptPath\$SQLINSTALLCONFIG_XML"
if (CheckFileExists($configFile) -eq $true)
{
    log "INFO: Found $configFile"
}
else
{
    throw "ERROR: $configFile does not exist"
}

$user = (Get-VariableValue $USER "agilitydeploy" $true)
$password = (get-globalvariable("ServiceAccount\$user")).value
        
$domain = get-domainshortname

$svc_sql = (Get-VariableValue $SVC_SQL "svc_sql" $true)       
$svc_sql_pwd = (get-globalvariable("ServiceAccount\$svc_sql")).value

log "INFO: admin user = $domain\$user"
log "INFO: sql user = $domain\$svc_sql"

# If a parameter hasn't been set, value from the ini file will be used
# If you have multiple ini files configured, ensure INSTANCENAME doesn't contain any value. 
# This set of parameters will be applied to ALL configuration ini files that are listed in the config xml

$parameters = @{}

$parameters.Add("DOMAIN", $domain)
$parameters.Add("SQLSVCACCOUNT", "$domain\$svc_sql")
$parameters.Add("AGTSVCACCOUNT", "$domain\$svc_sql")
$parameters.Add("ISSVCACCOUNT", "$domain\$svc_sql")
$parameters.Add("ASSVCACCOUNT", "$domain\$svc_sql")
$parameters.Add("RSSVCACCOUNT", "$domain\$svc_sql")
$parameters.Add("SQLSVCPASSWORD", $svc_sql_pwd)
$parameters.Add("AGTSVCPASSWORD", $svc_sql_pwd)
$parameters.Add("ISSVCPASSWORD", $svc_sql_pwd)
$parameters.Add("ASSVCPASSWORD", $svc_sql_pwd)
$parameters.Add("RSSVCPASSWORD", $svc_sql_pwd)
$parameters.Add("SQLSYSADMINACCOUNTS", "$domain\$user")
$parameters.Add("ASSYSADMINACCOUNTS", "$domain\$user")

$instName = $INSTANCENAME
$sqlFeatures = $FEATURES

if ( !([string]::IsNullOrEmpty($instName ) ) )         
{
    $parameters.Add("INSTANCENAME", $instName)
    $parameters.Add("INSTANCEID", $($instName).ToUpper())
    $parameters.Add("FEATURES", $sqlFeatures)
    log "INFO: SQL Variables: `ninstName = $instName; `nsqlFeatures = $sqlFeatures"
}

$secure_pwd = convertto-securestring $password -asplaintext -force
$dcred = new-object -typename System.Management.Automation.PSCredential -argumentlist "$domain\$user", $secure_pwd 
    
UpdateSQLConfigurationFiles $configFile $parameters 

ExecuteSQLConfigurationFiles $scriptPath $configFile $dcred $parameters

log "INFO: ****************************"
log "SQL Installation has completed"
