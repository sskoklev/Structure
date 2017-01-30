#################################################################################################
# Author: Stiven Skoklevski
# Desc:   Functions to support preparation of Windows Cluster
#################################################################################################

. .\FilesUtility.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1

if([String]::IsNullOrEmpty($SHAREDWINDOWSCLUSTERXMLFILENAME))
{
   log "ERROR: The clusterXMLfile parameter is null or empty."
}
else
{
    # *** configure and validate existence of input file
    $inputFile = "$scriptPath\$SHAREDWINDOWSCLUSTERXMLFILENAME"

    if ((CheckFileExists( $inputFile)) -ne $true)
    {
        log "ERROR: $inputFile is missing, users will not be configured."
        return
    }

    log "INFO: ***** Executing $inputFile ***********************************************************"

    # Get the xml Data
    $xml = [xml](Get-Content $inputFile)
 
    $nodes = $xml.SelectNodes("//doc/WindowsCluster")
    
    if (([string]::IsNullOrEmpty($nodes)))
    {
        log "No cluster settings to configure in: '$inputFile'"
        return
    }


    foreach ($node in $nodes) 
    {
        $clusterName = $node.GetAttribute("ClusterName").ToUpper() 

        $scriptPath = split-path -Parent $MyInvocation.MyCommand.Definition

        $domain = get-domainshortname
        $user = (Get-VariableValue $ADMIN "agilitydeploy" $true)
        $password = get-serviceAccountPassword -username $user

        $currentUser = $env:USERNAME

        $process = "$PSHOME\powershell.exe"
        $argument = "-file $scriptPath\Install\PreStageClusterADObjects.ps1 -scriptPath $scriptPath -clusterNames $clusterName -currentUser '$domain\$currentUser' ; exit `$LastExitCode"
        log "INFO: Calling $process under identity $domain\$user"
        log "INFO: Arguments $argument"

        try
        {
            $Result = LaunchProcessAsUser $process $argument "$domain\$user" $password

            log "LaunchProcessAsUser result: $Result"

            # check if error.txt exists. if yes, read it and throw exception
            # This is done to get an error code from the scheduled task.
            $errorFile = "$scriptPath\error.txt"
            if (CheckFileExists($errorFile))
            {
                $error = Get-Content $errorFile
                Remove-Item $errorFile
   
                throw $error
            }
	
            log "INFO: Finished Execute Create Cluster AD Objects."
            return 0
        }
        catch
        {
            log "ERROR: $($_.Exception.Message)"
        }
    }
}
