# MWS2R2 -Assign Replicate Dir Changes ##################################################################
# Author: Marina Krynina
#################################################################################################
try
{
	write-host "INFO: Attempting to assign Replicate Directory Changes permission to $SVC_IDENTITY"
	$scriptPath = $env:USERPROFILE

    . .\Assign-ReplicateDirChanges.ps1 -scriptPath $scriptPath -identity $SVC_IDENTITY

	exit 0
}
catch
{
	write-host "ERROR: $($_.Exception.Message)"
	exit 1
}