#########################################################################
# Author: Marina Krynina, CSC
# Updates:
#         2014-11-12 Added new function LaunchProcessAsAdministrator
#         2015-03-10 Updated LaunchProcessAsUser:
#                    - Exit code from the scheduled task is now returned
#                      by the function
#         2015-03-31 Updated LaunchProcessAsUser (sskoklev):
#                    - Delete the scheduled task if already exists
#########################################################################


#########################################################################
# Launch process as current user
#########################################################################
function LaunchProcessAsCurrentUser([string] $process, [string] $arguments)
{
    if ((IfFileExists $process) -eq $false)
    {
        return
    }

    try
    {
        log "INFO: Starting process $process"

        if([string]::IsNullOrEmpty($arguments))
        {
            $p = Start-Process -FilePath $process -Wait -PassThru -windowstyle Hidden
        }
        else
        {
            $p = Start-Process -FilePath $process -ArgumentList $arguments -Wait -PassThru -windowstyle Hidden
        }

        log "INFO: The process $process exit code is $($p.exitcode)"
    }
    catch [Exception]
    {
        log "ERROR: launching process $process."
        $ex = $_.Exception | format-list | Out-String
        log $ex

        throw
    } 
}

#########################################################################
# Launch process as local administrator
#########################################################################
function LaunchProcessAsAdministrator([string] $process, [string] $arguments)
{
    if ((IfFileExists $process) -eq $false)
    {
        log "ERROR: file $process does not exist"
        return 999
    }

    try
    {
        log "Starting process $process with the arguments = $arguments"

        if([string]::IsNullOrEmpty($arguments))
        {
            $p = Start-Process -FilePath $process -Verb RunAs -Wait -PassThru -windowstyle Hidden
        }
        else
        {
            $p = Start-Process -FilePath $process -ArgumentList $arguments -Verb RunAs -Wait -PassThru -windowstyle Hidden
        }

        log "The process $process exit code is $($p.exitcode)"

        return $p.exitcode
    }
    catch [Exception]
    {
        log "ERROR launching process $process."
        $ex = $_.Exception | format-list | Out-String
        log $ex

        throw $_.Exception
    } 
}

#########################################################################
# Launch process as doamin user
#########################################################################
function LaunchProcessAsDomainUser([string] $process, [string]$arguments, [System.Management.Automation.PSCredential] $dcred)
{
    if ((IfFileExists $process) -eq $false)
    {
        return
    }

    try
    {
        $command = "$process $arguments"
        $adminSession = New-PSSession -Credential $dcred;            
        Invoke-Command -Session $adminSession -Script { 
            Invoke-Expression $args[0];
        } -Args $command

        #log "The process $process exit code is $($p.exitcode)"
    }
    catch [Exception]
    {
        log "ERROR launching process $process."
        $ex = $_.Exception | format-list | Out-String
        log $ex

        throw
    } 
}

#########################################################################
# Launch process as user
#########################################################################
function LaunchProcessAsUser([string] $command, [string]$argument, [string] $username, [string] $password)
{
    if ((IfFileExists $command) -eq $false)
    {
        Return -1
    }

    try
    {

        $taskName = "AgilityTask"

        # sometimes when a script fails the task is not removed causing the next deployment to fail
        $taskExists = Get-ScheduledTask | Where-Object {$_.TaskName -eq $taskName} 
        if($taskExists)
        {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$False
            log "INFO: Schedule Task named: '$taskName' was found and deleted."
        }

        $action = New-ScheduledTaskAction -Execute $command -Argument $argument
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddHours(12)
        $s =  New-ScheduledTaskSettingsSet
        $d = New-ScheduledTask -Action $action  -Trigger $trigger -Settings $s
        $r = Register-ScheduledTask $taskName -InputObject $d -User $username -Password $password
        If ($r -eq $Null) {
            log "ERROR: Scheduled Task creation failed"
            Return -1
        }
        Start-ScheduledTask -TaskName $taskName
        Do {
            Start-Sleep -Seconds 10
            $task = Get-ScheduledTask -TaskName $taskName
        } Until ($task.State -eq "Ready")
        $TaskResult = (Get-ScheduledTaskInfo -TaskName $taskName).LastTaskResult
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        log "INFO: Task completed with return code $TaskResult"
        Return $TaskResult

    }
    catch [Exception]
    {
        log "ERROR launching process $process."
        $ex = $_.Exception | format-list | Out-String
        log $ex

        throw
    } 
}

#########################################################################
# Launch process as user with the higest privileges as user
#########################################################################
function LaunchProcessWithHighestPrivAsUser([string] $command, [string]$argument, [string] $username, [string] $password)
{
    if ((IfFileExists $command) -eq $false)
    {
        Return -1
    }

    try
    {
        $taskName = "AgilityTaskElevated"
        log "INFO: Creating task AgilityTaskElevated"

        # sometimes when a script fails the task is not removed causing the next deployment to fail
        $taskExists = Get-ScheduledTask | Where-Object {$_.TaskName -eq $taskName} 
        if($taskExists)
        {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$False
            log "INFO: Schedule Task named: '$taskName' was found and deleted."
        }

        $action = New-ScheduledTaskAction -Execute $command -Argument $argument
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddHours(12)
        
        # $s =  New-ScheduledTaskSettingsSet
        # $d = New-ScheduledTask -Action $action  -Trigger $trigger -Settings $s
        # $r = Register-ScheduledTask $taskName -InputObject $d -User $username -Password $password -RunLevel Highest 
        $r = Register-ScheduledTask $taskName -Action $action -Trigger $trigger -User $username -Password $password -RunLevel Highest

        If ($r -eq $Null) {
            log "ERROR: Scheduled Task creation failed"
            Return -1
        }
        Start-ScheduledTask -TaskName $taskName
        Do {
            Start-Sleep -Seconds 10
            $task = Get-ScheduledTask -TaskName $taskName
        } Until ($task.State -eq "Ready")
        $TaskResult = (Get-ScheduledTaskInfo -TaskName $taskName).LastTaskResult
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        log "INFO: Task completed with return code $TaskResult"
        Return $TaskResult

    }
    catch [Exception]
    {
        log "ERROR launching process $process."
        $ex = $_.Exception | format-list | Out-String
        log $ex

        throw
    } 
}
