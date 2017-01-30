.\PlatformUtils.ps1
. .\GlobalRepository.ps1

#get-serviceAccountPassword "svc_sql"

 $pwd =(get-globalvariable("ServiceAccount\svc_sql")).value


Write-Host $pwd