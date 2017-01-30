# ===================================================================================
# Author: Marina Krynina, CSC
# Func: ConstructURL
# Desc: if SSL ==> https://$urlbit.$suffix
#       if not ==> http://$urlbit.$suffix
# ===================================================================================
function ConstructURL ([string] $urlbit, [string] $suffix, [string]$useSSL)
{
    $siteUrl = $urlbit

    if (!([string]::IsNullOrEmpty($siteUrl)))
    {
    
      if ($useSSL -eq $true)
      {
        $urlStart = "https://"
      }
      else
      {
        $urlStart = "http://"
      }
    
        if (!([string]::IsNullOrEmpty($siteUrl)))
        {
            if (($siteUrl.Contains("://")) -eq $false) 
            {
                $siteUrl = $urlStart + $siteUrl
            }

            if(($siteUrl.EndsWith($suffix)) -eq $false)
            {
                $siteUrl = $siteUrl + "." + $suffix
            }
        }
    }
    return $siteUrl
}