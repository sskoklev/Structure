############################################################################################
# Configure SSRS
# Author: Stiven Skoklevski 
# Assumption: MWSCore100 will always be provisioned and will always have the SSRS feature installed
############################################################################################


## NOT USED, REPLACED BY SQL INI CONFIGURATION


<#
$ns = Get-WmiObject -Class "__NAMESPACE" -Namespace "root\Microsoft\SqlServer\ReportServer"
# $rs_instance_name = "root\Microsoft\SqlServer\ReportServer\" + $ns.Name + "\v11"
$rs_instance_name = "root\Microsoft\SqlServer\ReportServer\RS_MWSCORE100\v11"
$rs_instance = Get-WmiObject -Class "MSReportServer_Instance" -Namespace $rs_instance_name


$sqlInstance = "SNDDBSSYD101W\MWSMOBILITY04"
$sqlInstance ="MSRS11.MWSSCOM07"

#>

function ConfigureSSRS()
{
    $user = "Sandpit\svc_sql"
    $pwd = "eCQ!&!PN5wusXwuW"

    # Assumption: MWSCore100 will always be provisioned and will always have the SSRS feature installed
    $s = New-Object Management.ManagementScope("root\Microsoft\SqlServer\ReportServer\RS_MWSCore100\v11\admin");
    $s.Connect();

    $sc = New-Object Management.ManagementClass("root\Microsoft\SqlServer\ReportServer\RS_MWSCore100\v11\admin:MSReportServer_ConfigurationSetting");
    $sc.Get();

    $insts = $sc.GetInstances()

    foreach ($inst in $insts) 
    {

        if($inst.InstanceName -ne "SSRSTEST")
        {
            continue
        }

        $dbSqlInstance = $inst.DatabaseServerName
        $reportServerName = $inst.VirtualDirectoryReportServer 
        $reportManagerName = $inst.VirtualDirectoryReportManager
        $dbName = "ReportServer_" + $inst.InstanceName

        $inst.RemoveURL("ReportServerWebService", "http://+:80", 1033);
        $inst.RemoveURL("ReportManager", "http://+:80", 1033);

        $inst.SetVirtualDirectory("ReportServerWebService", $reportServerName, 1033);
        $inst.SetVirtualDirectory("ReportManager", $reportManagerName, 1033);

        $inst.ReserveURL("ReportServerWebService", "http://+:80", 1033);
        $inst.ReserveURL("ReportManager", "http://+:80", 1033);

        # Create Reporting Services Database
        $script = $inst.GenerateDatabaseCreationScript($dbName, 1033, $false);
        $script.Script | Out-File rs.sql
        sqlcmd -S $dbSqlInstance -i rs.sql

        $script = $inst.GenerateDatabaseRightsScript($user, $dbName, $false, $true);
        $script.Script | Out-File rs.sql
        sqlcmd -S $dbSqlInstance -i rs.sql

        $inst.SetDatabaseConnection($dbSqlInstance, $dbName, 2, "", "");

        $inst.SetWindowsServiceIdentity($false, $user, $pwd);

        $inst.SetServiceState($true, $true, $true);

}
}
############################################################################################
# Main
############################################################################################

# Load Common functions
. .\FilesUtility.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1

$scriptPath = "C:\Users\POCR01"
Set-Location -Path $scriptPath 
. .\LoggingV2.ps1 $true $scriptPath "ConfigureSSRS.ps1"

try
{

    $startDate = get-date

    log "INFO: Starting configuration of SSRS"

    ConfigureSSRS

    log "INFO: Finished configuration of SSRS"
    $endDate = get-date
    $ts = New-TimeSpan -Start $startDate -End $endDate
    log "TIME: Processing Time  - $ts"

    return 0
}
catch
{
    log "ERROR: $($_.Exception.Message)"
    throw "ERROR: $($_.Exception.Message)"
}