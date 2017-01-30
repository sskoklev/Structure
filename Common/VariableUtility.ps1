########################################################################################################
# Gets or sets variable value
# IMPORTANT: DO NOT output any logging from the function as it will pollute return value
########################################################################################################
function Get-VariableValue([string] $VARIABLE, [string] $defaultValue, [bool] $useHardcodedDefaults)
{
    if ([string]::IsNullOrEmpty($VARIABLE)) 
    {
        if ($useHardcodedDefaults)
        {
            log "WARNING: VARIABLE is null or empty, setting to provided default $defaultValue"
            $var = $defaultValue
        }
        else
        {
            log "INFO: VARIABLE is null or empty, Default is not set, setting to empty string"
            $var = ""
        }
    }
    else
    {
        $var = $VARIABLE
    }

    return $var
}