Import-Module OfficeWebApps 
(Invoke-WebRequest https://OfficeApps.MWSAust.NET/op/servicebusy.htm).Headers["X-OfficeVersion"]