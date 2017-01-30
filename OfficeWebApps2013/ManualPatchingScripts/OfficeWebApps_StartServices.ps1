#Start Services


Set-Service -Name "IISADMIN" -startuptype Automatic

$iissrv = get-service "IISADMIN"
$iissrv.start()
