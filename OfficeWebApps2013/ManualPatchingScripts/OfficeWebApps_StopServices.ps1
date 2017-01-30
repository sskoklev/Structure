#Stop Services



Set-Service -Name "IISADMIN" -startuptype Disabled

iisreset -stop -noforce



