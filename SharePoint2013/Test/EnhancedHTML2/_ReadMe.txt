Check your Powershell Module Path. Run $env:PSModulePath.Split(“;”) for example:ModPath
Create a folder named “EnhancedHTML2? under any of the listed paths like c:\Program Files\WindowsPowerShell\Modules\EnhancedHTML2
Copy the 2 files EnhancedHTML2.psd1 and EnhancedHTML2.psm1 to this folder (part of the downloaded files from #1 above)
Finally run Import-Module EnahncedHTML2