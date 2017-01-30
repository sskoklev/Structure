# Set-PageFile.ps1
#########################################################################
# Author: Stiven Skoklevski,
# Remove the existing PageFile and replace with new PageFile as per parameters
# Reboot is not required if moving to new drive for first time.
# If updating existing PageFile configuration than a reboot will most likely be required
# Eg of parameter: 
#     $PAGEFILEPATH = 'F:\pagefile.sys'
#     $INITIALSIZEMB = 48000
#     $MAXIMUMSIZEMB = 48000
# The above example will move the pagefile to Drive F:, name it pagefile.sys and set the initial and max size to 48GB
# Move often than not the inital and maximum should be the same.
#########################################################################

log "INFO: Create new PageFile at $PAGEFILEPATH with minimum size of $INITIALSIZEMB and maximum size of $MAXIMUMSIZEMB"

$ComputerSystem = $null
$CurrentPageFile = $null
$Modified = $false

# Disables automatically managed page file setting first
$ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem -EnableAllPrivileges
if ($ComputerSystem.AutomaticManagedPagefile)
{
    $ComputerSystem.AutomaticManagedPagefile = $false
    $ComputerSystem.Put()
    log "INFO: Disabled automatically managed page file setting."
}

$CurrentPageFile = Get-WmiObject -Class Win32_PageFileSetting
if ($CurrentPageFile.Name -eq $PAGEFILEPATH)
{
    # Keeps the existing page file
    if ($CurrentPageFile.InitialSize -ne $INITIALSIZEMB)
    {
        $CurrentPageFile.InitialSize = $INITIALSIZEMB
        $Modified = $true
    }
    if ($CurrentPageFile.MaximumSize -ne $MAXIMUMSIZEMB)
    {
        $CurrentPageFile.MaximumSize = $MAXIMUMSIZEMB
        $Modified = $true
    }
    if ($Modified)
    {
        $CurrentPageFile.Put()
        log "INFO: $PAGEFILEPATH already existed so only the size was adjusted."
    }
    else
    {
        log "INFO: The existing PageFile configuration matches the new configuration, so no changes have been performed."
    }
}
else
{
    # Creates a new page file
    $CurrentPageFile.Delete()
    log "INFO: The old PageFile $($CurrentPageFile.Name) has been deleted."

   Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{Name=$PAGEFILEPATH; InitialSize = $INITIALSIZEMB; MaximumSize = $MAXIMUMSIZEMB}
   log "INFO: The new PageFile $PAGEFILEPATH has been created."
}
