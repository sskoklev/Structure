# Client 0
New-SelfSignedCertificate -DnsName OfficeAppsClient0.mwsaust.net,devappsyd015w.devraus01.cscmws.com -CertStoreLocation Cert:\LocalMachine\My

# Demo
New-SelfSignedCertificate -DnsName OfficeApps.mwsaust.net,devappsyd005w.devraus01.cscmws.com,devappsyd006w.devraus01.cscmws.com -CertStoreLocation Cert:\LocalMachine\My