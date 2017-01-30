# Set-EnvironmentVariables.ps1
#########################################################################
# Author: Marina Krynina,
# Set environment variables.
# Eg of parameter: 
#     $ENVVARIABLES = "AppDrive~E:|LogDrive~L:|"
# The above example will create AppDrive machine environment variable 
#     with value E: and LogDrive machine env variable with value L:
#########################################################################

if([String]::IsNullOrEmpty($ENVVARIABLES))
{
   log "The ENVVARIABLES parameter is null or empty."
}
else
{
    $option = [System.StringSplitOptions]::RemoveEmptyEntries
    $variablesSets = $ENVVARIABLES.Split('|', $option)

    foreach($varSet in $variablesSets)
    {
        $currentVarSet = $varSet.Split('~', $option)

        $varName = $currentVarSet[0]
        $varValue = $currentVarSet[1]

        if([String]::IsNullOrEmpty($varName))
        {
           log "WARNING: The varName parameter is null or empty."
           continue
        }

        if([String]::IsNullOrEmpty($varValue))
        {
           log "WARNING: The varValue parameter is null or empty."
           continue
        }

        [Environment]::SetEnvironmentVariable($varName, $varValue, "Machine")
    }
}