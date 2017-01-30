/******************************************************************************************************************
**  Copyright (c) 2012 Microsoft Corporation.
**  All Rights Reserved
**  Purpose:
**          Updates\Initializes database tables
******************************************************************************************************************/


-- Replace SchemaChanges table with SchemaVersion table
RAISERROR('Removing SchemaChanges table', 0, 1) WITH NOWAIT
GO
IF (EXISTS (SELECT * FROM [INFORMATION_SCHEMA].[TABLES] WHERE [TABLE_NAME] = 'SchemaChanges'))
BEGIN
	DROP TABLE [SchemaChanges]
	INSERT INTO [SchemaVersion] VALUES (1)
END
GO

RAISERROR('Updating Configuration table', 0, 1) WITH NOWAIT
GO
IF NOT EXISTS (SELECT * FROM Configuration WHERE Name = 'PublishingSequenceNumber')
BEGIN
	INSERT INTO Configuration VALUES ('PublishingSequenceNumber', '0')
END
GO

RAISERROR('Updating schema to version 2', 0, 1) WITH NOWAIT
GO
IF EXISTS (SELECT * FROM [SchemaVersion] WHERE [Version] < 2)
BEGIN
	-- Add PackageOptional and VersionOptional columns to PackageGroupMemebers table
	ALTER TABLE PackageGroupMembers ADD PackageOptional bit NOT NULL DEFAULT 0, VersionOptional bit NOT NULL DEFAULT 0
	-- Update SchemaVersion table to version 2
	DELETE FROM [SchemaVersion]
	INSERT INTO [SchemaVersion] VALUES (2)
END
GO

-- Erase the current schema version from the SchemaVersion table (the new current version will be written during the install)
RAISERROR('Removing current schema version', 0, 1) WITH NOWAIT
GO
DELETE FROM [SchemaVersion]
GO
