/******************************************************************************************************************
**  Copyright (c) 2012 Microsoft Corporation.
**  All Rights Reserved
**  Purpose:
**          Creates user logins, sets up database roles and access to specific tables.
** 
**          NOTE: PLEASE REPLACE ACCOUNTS AND SIDS FOR READ AND WRITE ACCESS BEFORE EXECUTING THIS SCRIPT   
**
**          ManagementDbPublicAccessAccount should be the account corresponding to the user who
**          will be installing Management Service.
**
**          ManagementDbWriteAccessAccount should be the account corresponding to the remote server
**          where Management service will be installed. In case the service is going to be installed
**          on the local server, please use the following values,
**            "NT AUTHORITY\NETWORK SERVICE" for ManagementDbWriteAccessAccountName
**            "010100000000000514000000" for ManagementDbWriteAccessAccountSid
** 
******************************************************************************************************************/

RAISERROR('Granting access on SchemaChanges table to Public role', 0, 1) WITH NOWAIT
GO

/* Grants access on SchemaChanges table to Public role */
GRANT SELECT ON dbo.SchemaChanges TO PUBLIC
GO

RAISERROR('Setting up server login and db login for read-access to SchemaChanges table', 0, 1) WITH NOWAIT
GO

/* Setting up server login and db login for read-access to SchemaChanges table */
EXEC dbo.spSetupLogin 0x1521163369459738888859646116175632199, N'devraus01\AppvRead', 0
GO

RAISERROR('Setting up server login, db login and db roles for write-access to AppVManagement database', 0, 1) WITH NOWAIT
GO

/* Setting up server login, db login and db roles for write-access to AppVManagement database */
EXEC dbo.spSetupLogin 0x1521163369459738888859646116175632200, N'devraus01\AppvWrite', 1
GO
