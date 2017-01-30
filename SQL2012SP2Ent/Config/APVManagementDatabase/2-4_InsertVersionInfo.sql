/******************************************************************************************************************
**  Copyright (c) 2012 Microsoft Corporation.
**  All Rights Reserved
**  Purpose:
**          Inserts database version and min version of supported service information into SchemaChanges table
******************************************************************************************************************/

RAISERROR('Inserting schema version information', 0, 1) WITH NOWAIT
GO

DECLARE @minserviceversion             nvarchar(16)
DECLARE @dbversion              nvarchar(16)

BEGIN
    /* Define the version numbers. */
    SELECT @minserviceversion = N'5.0.10107.0'
    SELECT @dbversion  = N'5.0.10107.0'


    INSERT INTO dbo.SchemaChanges VALUES(@dbversion, @minserviceversion)

END 
GO
