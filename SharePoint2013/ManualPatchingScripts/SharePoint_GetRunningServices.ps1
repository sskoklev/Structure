#Lists down the services which is running and outputs to a file with computername and datetime concatenated
#expects a subfolder with the name ServicesStatusHistory in where the file is run
#Author = Kulothunkan Palasundram (kpalasundram)
#Date = 15 May 2016

$hostname = hostname
$currentdatetime = $(((get-date).ToUniversalTime()).ToString("yyyyMMddThhmmssZ"))
$filename = $hostname + "_" + "$currentdatetime.csv"

Get-Service | Where-Object {$_.status -eq "running"} |
Sort-Object displayname | Select displayname, status |
Export-Csv "$pwd\ServicesStatusHistory\$filename"