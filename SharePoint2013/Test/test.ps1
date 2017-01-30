$webclient = new-object System.Net.WebClient
    $webClient.UseDefaultCredentials = $true

    try
    {
    $webpage = $webclient.DownloadString("http://www.cnn.com")
    $str = [string]$webpage
    $start = $str.IndexOf("<title>", [System.StringComparison]::OrdinalIgnoreCase)
    $end = $str.IndexOf("</title>", [System.StringComparison]::OrdinalIgnoreCase)
    $s = $str.Substring($strat, $end)
    $s
    }
    catch
    {
        Write-host  $($_.Exception.Message) 
    }

