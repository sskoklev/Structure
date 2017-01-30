$SPFarm = [Microsoft.SharePoint.Administration.SPFarm]::Local 
   
#region - Alternate Access Mapping
$AAM = $SPFarm.AlternateUrlCollections | 
       ConvertTo-EnhancedHTMLFragment -EvenRowCssClass 'even' `
                                      -OddRowCssClass 'odd' `
                                      -MakeHiddenSection `
                                      -PreContent '<h4>+ Alternate Access mappings</h4>'
#endregion


#region - SharePoint Build Version
$buildversion = $SPFarm.BuildVersion | 
                ConvertTo-EnhancedHTMLFragment -EvenRowCssClass 'even' `
                                               -OddRowCssClass 'odd' `
                                               -MakeHiddenSection `
                                               -PreContent '<h4>+ SharePoint Build Version</h4>'
#endregion

#region
$Servers = $SPFarm.Servers | 
           Select Address , DisplayName , ID , Status | 
           ConvertTo-EnhancedHTMLFragment -EvenRowCssClass 'even' `
                                          -OddRowCssClass 'odd' `
                                          -MakeHiddenSection `
                                          -PreContent '<h4>+ SharePoint Farm Servers</h4>'
#endregion

#region
$SPFarmFeatures = $SPFarm.FeatureDefinitions | ? {$_.Scope -eq 'Farm'} |
                  Select DisplayName , ID , Status , CompatibilityLevel | 
                  ConvertTo-EnhancedHTMLFragment -EvenRowCssClass 'even' `
                                                 -OddRowCssClass 'odd' `
                                                 -MakeHiddenSection `
                                                 -PreContent '<h4>+ SharePoint Farm Feature Definitions</h4>'
#endregion

#region
$SPWebFeatures = $SPFarm.FeatureDefinitions | ? {$_.Scope -eq 'Web'} |
                  Select DisplayName , ID , Status , CompatibilityLevel | 
                  ConvertTo-EnhancedHTMLFragment -EvenRowCssClass 'even' `
                                                 -OddRowCssClass 'odd' `
                                                 -MakeHiddenSection `
                                                 -PreContent '<h4>+ SharePoint Web Feature Definitions</h4>'
#endregion

#region
$SPSiteFeatures = $SPFarm.FeatureDefinitions | ? {$_.Scope -eq 'Site'} | 
                  Select DisplayName , ID , Status , CompatibilityLevel | 
                  ConvertTo-EnhancedHTMLFragment -EvenRowCssClass 'even' `
                                                 -OddRowCssClass 'odd' `
                                                 -MakeHiddenSection `
                                                 -PreContent '<h4>+ SharePoint Site Feature Definitions</h4>'
#endregion

#region
$SPServiceProxy = $SPFarm.ServiceProxies| 
                  ConvertTo-EnhancedHTMLFragment -EvenRowCssClass 'even' `
                                                 -OddRowCssClass 'odd' `
                                                 -MakeHiddenSection `
                                                 -PreContent '<h4>+ SharePoint Service Proxy</h4>'
#endregion
ConvertTo-EnhancedHTML -HTMLFragments $AAM , $buildversion , $Servers , $SPFarmFeatures , $SPWebFeatures ,`
                                      $SPSiteFeatures , $SPServiceProxy `
                       -CssUri C:\users\mktynina\test\StyleS.css | Out-File C:\users\mkrynina\test\Farm.html -Encoding ascii
