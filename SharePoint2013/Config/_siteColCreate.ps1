
$siteURL = "https://DEVAPPSYD001W.devraus01.cscmws.com"
$ownerAlias = "DEVRAUS01\agilitydeploy"

<SiteCollection siteUrl="https://DEVAPPSYD001W.devraus01.cscmws.com" HostNamedSiteCollection="false" Owner="DEVRAUS01\agilitydeploy" Name="Root Site Collection" Description="MWS2 Root Site Collection. The site collection is locked." CustomDatabase="" SearchUrl="" CustomTemplate="false" LCID="1033" Locale="en-us" Time24="true" />


New-SPSite -Url $siteURL -OwnerAlias $ownerAlias -SecondaryOwner $env:USERDOMAIN\$env:USERNAME -ContentDatabase $siteDatabase -Description $siteCollectionName -Name $siteCollectionName -Language $LCID @templateSwitch @hostHeaderWebAppSwitch -ErrorAction Stop




$hostHeaderWebAppSwitch = @{HostHeaderWebApplication = $($webApp.url)+":"+$($webApp.port)}

Template="STS#0"

New-SPSite -Url https://DEVAPPSYD001W.devraus01.cscmws.com -OwnerAlias DEVRAUS01\agilitydeploy -SecondaryOwner DEVRAUS01\agilitydeploy -ContentDatabase SP_Content_WebApp -Description "Root Site Collection" -Name "Root Site Collection" -Language 1033 -Template "STS#0"  -ErrorAction Stop

New-SPSite -Url https://DEVAPPSYD001W.devraus01.cscmws.com -OwnerAlias DEVRAUS01\svc_sp_farm -SecondaryOwner DEVRAUS01\svc_sp_farm -ContentDatabase SP_Content_WebApp -Description "Root Site Collection" -Name "Root Site Collection" -Language 1033  -ErrorAction Stop


SPRequest.CreateSite: UserPrincipalName=, 
AppPrincipalName= ,gApplicationId=4b49cedd-21f2-453a-a5b2-6994399203ff ,
bstrUrl=https://devappsyd001w.devraus01.cscmws.com/ ,lZone=0 ,gSiteId=b6cd81a0-1ae2-4178-94f3-c65e79dd4290 ,
gDatabaseId=4bb2eb4f-5db7-4cc2-8419-95b69633c056 ,bstrDatabaseServer=SP_CONTENT ,bstrDatabaseName=SP_Content_WebApp ,
bstrDatabaseUsername=<null> ,bstrDatabasePassword=<null> ,bstrTitle=Root Site Collection ,bstrDescription=Root Site Collection ,nLCID=1033 ,
bstrOwnerLogin=i:0#.w|devraus01\agilitydeploy ,bstrOwnerUserKey=i:0).w|s-1-5-21-1633694597-3888885964-611617563-1221 ,
bstrOwnerName=DEVRAUS01\agilitydeploy ,bstrOwnerEmail=<null> ,bstrSecondaryContactLogin=i:0#.w|devraus01\agilitydeploy ,
bstrSecondaryContactUserKey=i:0).w|s-1-5-21-1633694597-3888885964-611617563-1221 ,bstrSecondaryContactName=DEVRAUS01\agilitydeploy ,bstrSecondaryContactEmail=<null> ,bADAccountMode=False ,
bHostHeaderIsSiteName=False ,iDatabaseVersionMajor=15 ,iDatabaseVersionMinor=0 ,iDatabaseVersionBuild=146 ,iDatabaseVersionRevision=0 ,bstrSiteSchemaVersion=15.0.35.0



New-SPSite -Url https://DEVAPPSYD001W.devraus01.cscmws.com -OwnerAlias DEVRAUS01\agilitydeploy -SecondaryOwner DEVRAUS01\agilitydeploy -ContentDatabase SP_Content_WebApp -Description "Root Site Collection" -Name "Root Site Collection" -Language 1033 -Template STS#0  -ErrorAction Stop