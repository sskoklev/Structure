/******************************************************************************************************************
**  Copyright (c) 2012 Microsoft Corporation.
**  All Rights Reserved
**  Purpose:
**          Creates the tables for AppVManagement database
******************************************************************************************************************/

/*****************************************************************************************************************
** Table dbo.Configuration contains list of configuration items for the management server
******************************************************************************************************************/
RAISERROR('Creating table dbo.Configuration', 0, 1) WITH NOWAIT
GO
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='configuration' AND xtype='U')
BEGIN
    CREATE TABLE dbo.Configuration (
            Id                  int PRIMARY KEY IDENTITY,
            Name                nvarchar(100) NOT NULL,
            Value               nvarchar(1024) NOT NULL
    )

    CREATE NONCLUSTERED INDEX IdxConfigurationName ON Configuration(Name)
END
GO

/*****************************************************************************************************************
** Table dbo.PackageGroups contains list of all the Package groups
******************************************************************************************************************/
RAISERROR('Creating table dbo.PackageGroups', 0, 1) WITH NOWAIT
GO
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='PackageGroups' AND xtype='U')
BEGIN
    CREATE TABLE dbo.PackageGroups (
            Id                  int PRIMARY KEY IDENTITY,
            Description         nvarchar(256),
            Guid                uniqueidentifier NOT NULL,
            VersionGuid         uniqueidentifier NOT NULL,
            VersionNumber       int NOT NULL,
            Name                nvarchar(100) NOT NULL,
            Enabled             bit NOT NULL  DEFAULT 0,
            Priority            int NOT NULL,
    )

    CREATE NONCLUSTERED INDEX IdxPackageGroupsId ON PackageGroups(Id)
    CREATE NONCLUSTERED INDEX IdxPackageGroupsName ON PackageGroups (Name)
END
GO

/*****************************************************************************************************************
** Table dbo.PackageVersions contains list of all the Package versions
******************************************************************************************************************/
RAISERROR('Creating table dbo.PackageVersions', 0, 1) WITH NOWAIT
GO
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='PackageVersions' AND xtype='U')
BEGIN
    CREATE TABLE dbo.PackageVersions (
            Id                          int PRIMARY KEY IDENTITY,
            PackageGuid                 uniqueidentifier NOT NULL,
            Name                        nvarchar(100) NOT NULL,
            Description                 nvarchar(256),
            VersionGuid                 uniqueidentifier NOT NULL UNIQUE,
            VersionNumber               nvarchar(100) NOT NULL,
            Size                        bigint NOT NULL,
            PackageUrl                  nvarchar(1024) NOT NULL,
            UserPolicyFromManifest      nvarchar(MAX) NOT NULL,
            MachinePolicyFromManifest   nvarchar(MAX) NOT NULL,
            SupportedOSsFromManifest	nvarchar(512),   
			SequencerArchitecture		nvarchar(16) NOT NULL,        
            Enabled                     bit NOT NULL  DEFAULT 0,
            TimeAdded                   DateTime NOT NULL,
            TimeChanged                 DateTime,
            TimeEnabled                 DateTime,
            ClientVersion               int DEFAULT 0,
    )

    ALTER TABLE dbo.PackageVersions ADD 
        CONSTRAINT CKPackageVersionsSize CHECK (Size >= 0),
        CONSTRAINT CKPackageVersionsClientVersion CHECK (ClientVersion >= 0)


    CREATE NONCLUSTERED INDEX IdxPackageVersionsId ON PackageVersions(Id)
    CREATE NONCLUSTERED INDEX IdxPackageVersionsName ON PackageVersions(Name)
    CREATE NONCLUSTERED INDEX IdxPackageVersionsPackageGuid ON PackageVersions(PackageGuid)
    CREATE NONCLUSTERED INDEX IdxPackageVersionsVersionGuid ON PackageVersions(VersionGuid)
    CREATE NONCLUSTERED INDEX IdxPackageVersionsEnabled ON PackageVersions(Enabled)
END
GO

/*****************************************************************************************************************
** Table dbo.PackageGroupMembers contains list of Package versions for each Package group
******************************************************************************************************************/
RAISERROR('Creating table dbo.PackageGroupMembers', 0, 1) WITH NOWAIT
GO
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='PackageGroupMembers' AND xtype='U')
BEGIN
    CREATE TABLE dbo.PackageGroupMembers (
            Id                              int PRIMARY KEY IDENTITY,
            PackageGroupId                  int NOT NULL,
            PackageVersionId                int NOT NULL,
            LoadOrder                       int NOT NULL,
			PackageOptional					bit NOT NULL DEFAULT 0,
			VersionOptional					bit NOT NULL DEFAULT 0
    )

    ALTER TABLE dbo.PackageGroupMembers ADD 
	CONSTRAINT FKPackageGroupMembersPackageGroupId FOREIGN KEY 
	(
		PackageGroupId
	) REFERENCES dbo.PackageGroups (
		Id
	) ON DELETE CASCADE  NOT FOR REPLICATION


    ALTER TABLE dbo.PackageGroupMembers ADD 
	CONSTRAINT FkPackageGroupMembersPackageVersionId FOREIGN KEY 
	(
		PackageVersionId
	) REFERENCES dbo.PackageVersions (
		Id
	) ON DELETE CASCADE  NOT FOR REPLICATION


    ALTER TABLE dbo.PackageGroupMembers ADD 
        CONSTRAINT UqPackageGroupMembers UNIQUE (PackageGroupId, PackageVersionId)

    CREATE NONCLUSTERED INDEX IdxPackageGroupMembersPackageGroupId ON PackageGroupMembers(PackageGroupId)
    CREATE NONCLUSTERED INDEX IdxPackageGroupMembersPackageVersionId ON PackageGroupMembers(PackageVersionId)

END
GO

/*****************************************************************************************************************
** Table dbo.PackageGroupEntitlements contains list of all entitlements for package groups
******************************************************************************************************************/
RAISERROR('Creating table dbo.PackageGroupEntitlements', 0, 1) WITH NOWAIT
GO
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='PackageGroupEntitlements' AND xtype='U')
BEGIN
    CREATE TABLE dbo.PackageGroupEntitlements (
            Id                              int PRIMARY KEY IDENTITY,
            PackageGroupId                  int NOT NULL,
            Sid                             nvarchar (184) NOT NULL
    )

    ALTER TABLE dbo.PackageGroupEntitlements ADD 
	CONSTRAINT FKPackageGroupEntitlementsPackageGroupId FOREIGN KEY 
	(
		PackageGroupId
	) REFERENCES dbo.PackageGroups (
		Id
	) ON DELETE CASCADE  NOT FOR REPLICATION

END
GO


/*****************************************************************************************************************
** Table dbo.PackageEntitlements contains list of entitlements for each Package version
******************************************************************************************************************/
RAISERROR('Creating table dbo.PackageEntitlements', 0, 1) WITH NOWAIT
GO
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='PackageEntitlements' AND xtype='U')
BEGIN
    CREATE TABLE dbo.PackageEntitlements (
            Id                 int PRIMARY KEY IDENTITY,
            PackageVersionId   int NOT NULL,
            Sid                nvarchar (184),
            UserConfigurationContent         nvarchar(MAX),
            UserConfigurationTimestamp       DateTime NOT NULL
    )


    ALTER TABLE dbo.PackageEntitlements ADD 
	CONSTRAINT FkPackageEntitlementsPackageVersionId FOREIGN KEY 
	(
		PackageVersionId
	) REFERENCES dbo.PackageVersions (
		Id
	) ON DELETE CASCADE  NOT FOR REPLICATION


    CREATE NONCLUSTERED INDEX IdxPackageEntitlementsPackageVersionId ON PackageEntitlements(PackageVersionId)
    CREATE NONCLUSTERED INDEX IdxPackageEntitlementsSid ON PackageEntitlements(Sid)

END
GO


/*****************************************************************************************************************
** Table dbo.Applications contains list of applications for each Package version
******************************************************************************************************************/
RAISERROR('Creating table dbo.Applications', 0, 1) WITH NOWAIT
GO
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Applications' AND xtype='U')
BEGIN
    CREATE TABLE dbo.Applications (
            Id                 bigint PRIMARY KEY IDENTITY,
            PackageVersionId   int NOT NULL,
	    ApplicationId      nvarchar(1024) NOT NULL,
            Target             nvarchar(256),
            Name               nvarchar(256) NOT NULL,
            Icon               nvarchar(256),
            Description        nvarchar(256)
    )


    ALTER TABLE dbo.Applications ADD 
	CONSTRAINT FkApplicationsPackageVersionId FOREIGN KEY 
	(
		PackageVersionId
	) REFERENCES dbo.PackageVersions (
		Id
	) ON DELETE CASCADE  NOT FOR REPLICATION


    CREATE NONCLUSTERED INDEX IdxPackageEntitlementsPackageVersionId ON Applications (PackageVersionId)
END
GO


/*****************************************************************************************************************
** Table dbo.Applications contains list of shortcuts for each application
******************************************************************************************************************/
RAISERROR('Creating table dbo.Shortcuts', 0, 1) WITH NOWAIT
GO
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Shortcuts' AND xtype='U')
BEGIN
    CREATE TABLE dbo.Shortcuts (
            Id                 bigint PRIMARY KEY IDENTITY,
            PackageVersionId   int NOT NULL,
            ApplicationId      nvarchar(1024),
            FileName           nvarchar(1024) NOT NULL,
            Target             nvarchar(1024),
            Arguments          nvarchar(1024),
            AppUserModelId     nvarchar(1024),
            IconFile           nvarchar(1024),
            IconResourceIndex  int,
            WorkingDirectory   nvarchar(1024),
            Description        nvarchar(1024),
            ShowCommand        int,
            Hotkey             int
    )


    ALTER TABLE dbo.Shortcuts ADD 
	CONSTRAINT FkShortcutsPackageVersionId FOREIGN KEY 
	(
		PackageVersionId
	) REFERENCES dbo.PackageVersions (
		Id
	) ON DELETE CASCADE  NOT FOR REPLICATION


    CREATE NONCLUSTERED INDEX IdxShortcutsPackageVersionId ON Shortcuts (PackageVersionId)
END
GO



/*****************************************************************************************************************
** Table dbo.FileTypeAssociations contains list of FTAs
******************************************************************************************************************/
RAISERROR('Creating table dbo.FileTypeAssociations', 0, 1) WITH NOWAIT
GO
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='FileTypeAssociations' AND xtype='U')
BEGIN
    CREATE TABLE dbo.FileTypeAssociations (
            Id                          int PRIMARY KEY IDENTITY,
            PackageVersionId            int NOT NULL,
            ExtensionName               nvarchar(1024),
            ExtensionProgId             nvarchar(1024),
            ExtensionContentType        nvarchar(1024),
            ExtensionPerceivedType      nvarchar(1024),
            ShellNewCommand             nvarchar(1024),
            ShellNewDataBinary          varbinary(1024),
            ShellNewDataText            nvarchar(1024),
            ShellNewFileName            nvarchar(1024),
            ShellNewNullFile            bit,
            ShellNewItemName            nvarchar(1024),
            ShellNewIconPath            nvarchar(1024),
            ShellNewMenuText            nvarchar(1024),
            ShellNewHandler             uniqueidentifier
    )


    ALTER TABLE dbo.FileTypeAssociations ADD 
	CONSTRAINT FkFileTypeAssociationsPackageVersionId FOREIGN KEY 
	(
		PackageVersionId
	) REFERENCES dbo.PackageVersions (
		Id
	) ON DELETE CASCADE  NOT FOR REPLICATION


    CREATE NONCLUSTERED INDEX IdxFileTypeAssociationsPackageVersionId ON FileTypeAssociations (PackageVersionId)
END
GO



/*****************************************************************************************************************
** Table dbo.OpenWithApps contains list of applications to open with.
******************************************************************************************************************/
RAISERROR('Creating table dbo.OpenWithApps', 0, 1) WITH NOWAIT
GO
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='OpenWithApps' AND xtype='U')
BEGIN
    CREATE TABLE dbo.OpenWithApps (
            Id                      bigint PRIMARY KEY IDENTITY,
            FileTypeAssociationId   int NOT NULL,
            ApplicationName         nvarchar(1024) NOT NULL
    )


    ALTER TABLE dbo.OpenWithApps ADD 
	CONSTRAINT FkOpenWithAppsFileTypeAssociationId FOREIGN KEY 
	(
		FileTypeAssociationId
	) REFERENCES dbo.FileTypeAssociations (
		Id
	) ON DELETE CASCADE  NOT FOR REPLICATION

    CREATE NONCLUSTERED INDEX IdxOpenWithAppsFileTypeAssociationId ON OpenWithApps (FileTypeAssociationId)

END
GO


/*****************************************************************************************************************
** Table dbo.OpenWithProgIds contains list of ProgIDs to open with.
******************************************************************************************************************/
RAISERROR('Creating table dbo.OpenWithProgIds', 0, 1) WITH NOWAIT
GO
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='OpenWithProgIds' AND xtype='U')
BEGIN
    CREATE TABLE dbo.OpenWithProgIds (
            Id                      bigint PRIMARY KEY IDENTITY,
            FileTypeAssociationId   int NOT NULL,
            ProgId                  nvarchar(1024) NOT NULL
    )


    ALTER TABLE dbo.OpenWithProgIds ADD 
	CONSTRAINT FkOpenWithProgIdsFileTypeAssociationId FOREIGN KEY 
	(
		FileTypeAssociationId
	) REFERENCES dbo.FileTypeAssociations (
		Id
	) ON DELETE CASCADE  NOT FOR REPLICATION

    CREATE NONCLUSTERED INDEX IdxOpenWithProgIdsFileTypeAssociationId ON OpenWithProgIds (FileTypeAssociationId)

END
GO


/*****************************************************************************************************************
** Table dbo.PublishingServers contains list of publishing servers
******************************************************************************************************************/
RAISERROR('Creating table dbo.PublishingServers', 0, 1) WITH NOWAIT
GO
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='PublishingServers' AND xtype='U')
BEGIN
    CREATE TABLE dbo.PublishingServers (
            Id                      int PRIMARY KEY IDENTITY,
            Name                    nvarchar (255) UNIQUE NOT NULL,
            Sid                     nvarchar (184) UNIQUE NOT NULL,
            Description             nvarchar (1024),
            LastPublishingAttempt   DateTime
    )


    CREATE NONCLUSTERED INDEX IdxPublishingServersName ON PublishingServers (Name)
    CREATE NONCLUSTERED INDEX IdxPublishingServersSid ON PublishingServers (Sid)
END
GO


/*****************************************************************************************************************
** Table dbo.ProgIds contains list of ProgIDs.
******************************************************************************************************************/
RAISERROR('Creating table dbo.ProgIds', 0, 1) WITH NOWAIT
GO
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='ProgIds' AND xtype='U')
BEGIN
    CREATE TABLE dbo.ProgIds (
            Id                      int PRIMARY KEY IDENTITY,
            FileTypeAssociationId   int NOT NULL,
            Name                    nvarchar(1024),
            AppUserModelId          nvarchar(1024),
            DefaultIcon             nvarchar(1024),
            FriendlyTypeName        nvarchar(1024),
            InfoTip                 nvarchar(1024),
            EditFlags               nvarchar(1024),
            Description             nvarchar(1024),
            DefaultShellCommandName nvarchar(1024)
    )


    ALTER TABLE dbo.ProgIds ADD 
	CONSTRAINT FkProgIdsFileTypeAssociationId FOREIGN KEY 
	(
		FileTypeAssociationId
	) REFERENCES dbo.FileTypeAssociations (
		Id
	) ON DELETE CASCADE  NOT FOR REPLICATION

    CREATE NONCLUSTERED INDEX IdxProgIdsFileTypeAssociationId ON ProgIds (FileTypeAssociationId)

END
GO




/*****************************************************************************************************************
** Table dbo.ShellCommands contains list of ShellCommands for a particular ProgId
******************************************************************************************************************/
RAISERROR('Creating table dbo.ShellCommands', 0, 1) WITH NOWAIT
GO
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='ShellCommands' AND xtype='U')
BEGIN
    CREATE TABLE dbo.ShellCommands (
            Id                      int PRIMARY KEY IDENTITY,
            ProgIdId                int NOT NULL,
            Name                    nvarchar(1024) NOT NULL,
            CommandLine             nvarchar(1024),
            FriendlyName            nvarchar(1024),
            DropTargetClassId       uniqueidentifier,
            Extended                bit,
            LegacyDisable           bit,
            SuppressionPolicy       int,
            DdeExecApplicaiton      nvarchar(1024),
            DdeExecTopic            nvarchar(1024),
            DdeExecDdeCommand       nvarchar(1024),
            DdeExecIfExec           nvarchar(1024),
            ApplicationId           nvarchar(1024)
    )


    ALTER TABLE dbo.ShellCommands ADD 
	CONSTRAINT FkShellCommandsProgIdId FOREIGN KEY 
	(
		ProgIdId
	) REFERENCES dbo.ProgIds (
		Id
	) ON DELETE CASCADE  NOT FOR REPLICATION

    CREATE NONCLUSTERED INDEX IdxShellCommandsProgIdId ON ShellCommands (ProgIdId)

END
GO



/*****************************************************************************************************************
** Table dbo.RoleAssignments contains list of users and their roles
******************************************************************************************************************/
RAISERROR('Creating table dbo.RoleAssignments', 0, 1) WITH NOWAIT
GO
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='RoleAssignments' AND xtype='U')
BEGIN
    CREATE TABLE dbo.RoleAssignments (
            Id                 int PRIMARY KEY IDENTITY,
            RoleName           nvarchar(200) NOT NULL,
			Sid                nvarchar (184) NOT NULL,
            AccountType        int NOT NULL				/* Set AccountType to 0 for an AD group and 1 for AD user */
    )

	ALTER TABLE dbo.RoleAssignments ADD 
        CONSTRAINT UqADName UNIQUE (Sid, RoleName)

	CREATE NONCLUSTERED INDEX IdxRoleName ON RoleAssignments(RoleName)
END
GO

/*****************************************************************************************************************
** Table dbo.SchemaVersion contains the current schema version
******************************************************************************************************************/
RAISERROR('Creating table dbo.SchemaVersion', 0, 1) WITH NOWAIT
GO
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='SchemaVersion' AND xtype='U')
BEGIN
    CREATE TABLE dbo.SchemaVersion (
            Version                       int NOT NULL
    )

END
GO
   
