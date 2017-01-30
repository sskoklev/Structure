# Installed >NET Framework version and release
# release 378675 or 378758 = .NET 4.5.1
# release 379893 = .NET 4.5.2
Get-ChildItem 'Microsoft.Powershell.Core\Registry::HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse |
get-ItemProperty -name Version, Release -EA 0 |
Where {$_.PSChildName -match '^(?!S)\p{L}'} |
Select PSChildName, Version, Release

# Installed Programs
get-wmiobject -class win32_product | Format-Table Name, Version -AutoSize
