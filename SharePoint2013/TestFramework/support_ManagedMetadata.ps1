#Get-SPMetadataServiceApplication

#Get-SPMetadataServiceApplicationProxy

#Get-SPSiteSubscriptionMetadataConfig

#Get-SPTaxonomySession

$mmId = Get-SPServiceApplication | Where-Object {$_.DisplayName -like "*managed metadata*"} | Select Id
Get-SPServiceApplication -Identity $mmId

#Get-SPMetadataServiceApplication -Identity $mmId