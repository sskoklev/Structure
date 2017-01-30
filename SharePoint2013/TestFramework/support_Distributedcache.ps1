Use-CacheCluster
Get-CacheHost

Get-CacheHostConfig $env:COMPUTERNAME 22233

Get-CacheClusterHealth


# Remove and add a server to the Distributed Cache cluster
$instanceName ="SPDistributedCacheService Name=AppFabricCachingService" 
$serviceInstance = Get-SPServiceInstance | ? {($_.service.tostring()) -eq $instanceName -and ($_.server.name) -eq $env:computername}
$serviceInstance.Unprovision() 
$serviceInstance.Delete()
# get all servers that have Dictributed Cache enabled
Get-SPServiceInstance | ? {($_.service.tostring()) -eq "SPDistributedCacheService Name=AppFabricCachingService"} | select Server, Status
# enable Distributed cache on the server
Add-SPDistributedCacheServiceInstance
Get-SPServiceInstance | ? {($_.service.tostring()) -eq "SPDistributedCacheService Name=AppFabricCachingService"} | select Server, Status

# restarts Cache Cluster - restarts windows services
Restart-CacheCluster

# unregister CacheHost
Unregister-CacheHost -HostName [machine] -ProviderType SPDistributedCacheClusterProvider -ConnectionString \\[machine]

# Error: Specified host is not present in cluster.
Register-CacheHost –Provider [provider] –ConnectionString [connectionString]
-Account "NT AuthorityNetwork Service" -CachePort 22233 -ClusterPort 22234 -ArbitrationPort 22235
-ReplicationPort 22236 –HostName [serverName]

# Stop Chache Cluster
Stop-CacheCluster
Set-CacheHostConfig -CacheSize 1000 -HostName server1 -CachePort 22233