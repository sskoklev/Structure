/******************************************************************************************************************
**  Copyright (c) 2012 Microsoft Corporation.
**  All Rights Reserved
**  Purpose:
**          Creates the AppVirtManagement database
******************************************************************************************************************/
RAISERROR('Creating database if it does not exist', 0, 1) WITH NOWAIT
GO

/* Create the database if it doesn't exist */
IF NOT EXISTS (SELECT * FROM master..sysdatabases WHERE name='AppVirtManagement') 
  CREATE DATABASE [AppVirtManagement]
GO

RAISERROR('Setting ALLOW_SNAPSHOT_ISOLATION on the database', 0, 1) WITH NOWAIT
GO

/* Set ALLOW_SNAPSHOT_ISOLATION on the database */
ALTER DATABASE [AppVirtManagement] SET ALLOW_SNAPSHOT_ISOLATION ON
GO
