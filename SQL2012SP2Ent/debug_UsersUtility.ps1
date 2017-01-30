. .\PlatformUtils.ps1
. .\GlobalRepository.ps1
. .\LoggingV2.ps1 $true
. .\UsersUtility.ps1

$name = "svc_sql"
$pwd = get-serviceAccountPassword -username $name
Write-Host $pwd

$name = "svc_xdm"
$pwd = get-serviceAccountPassword -username $name
Write-Host $pwd

return



$DBInstanceName = "DR2CNNCDC004W\MWSMOBILITY04"
$name = "svc_sql" # "XDM"
$pwd = "WBjJsmn%dg#Tj2mm"
$SQLRoles="sysadmin,dbCreator"

# $login = CreateLocalSQLLogin $DBInstanceName $name $pwd
# AddSQlLoginToSQLRole  $DBInstanceName $SQLRoles $login

AssignSQLRoleToLocalUser $DBInstanceName $name $SQLRoles $pwd

return



$name = "ServiceAccount\SVC_XDM"

$pwd2 =    (get-globalvariable("$name")).value
Write-Host $pwd2


return



$pwd2 =    (get-globalvariable("$name")).value
Write-Host $pwd2

Add-Type -AssemblyName System.Web
Invoke-RestMethod -Method GET -Uri http://10.5.4.40:4001/v2/keys/

return

Add-Type -AssemblyName System.Web
Invoke-RestMethod -Method GET -Uri http://10.5.4.40:4001/v2/keys/ServiceAccount\svc_sql

return


#clean up for next run

<#

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
$srv = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "DR2CNNCDC004W\MWSMOBILITY04"
$srv.Logins["SVC_XDM"].Drop(); 

#>

