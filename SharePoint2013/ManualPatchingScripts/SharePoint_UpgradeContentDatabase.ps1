Add-PSSnapin Microsoft.SharePoint.Powershell

$web = Get-SPWebApplication -IncludeCentralAdministration

Write-Output $web

foreach( $url in $web.url)
{
    $contentdb = Get-SPContentDatabase -WebApplication $url

    Write-Output "`n Upgrading $contentdb ....`n"

    Upgrade-SPContentDatabase -Identity $contentdb.Id -Verbose -Confirm
}