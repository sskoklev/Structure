Import-Module OfficeWebApps 		
New-OfficeWebAppsFarm  -CacheLocation "E:\Program Files\Microsoft\OfficeWebApps\Working\d\" -CacheSizeInGB 15  -CertificateName "MWS2R2 OfficeApps"   -InternalURL "officeapps.mwsaust.net"   -ExternalUrl  "officeapps.mwsaust.net"   -LogLocation "L:\LogFiles\OfficeWebApps\ULS"   -LogRetentionInDays 7   -MaxMemoryCacheSizeInMB 75   -RenderingLocalCacheLocation "E:\ProgramData\Microsoft\OfficeWebApps\Working\waccache" -EditingEnabled $true  
-SSLOffloaded $false  -AllowHTTP $false  -Force  
