/******************************************************************************************************************
**  Copyright (c) 2012 Microsoft Corporation.
**  All Rights Reserved
**  Purpose:
**          Creates the stored procs for AppVManagement database
******************************************************************************************************************/


RAISERROR('Adding procedure spSetupLogin', 0, 1) WITH NOWAIT
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE TYPE = 'P' and name = 'spSetupLogin')
    DROP PROCEDURE dbo.spSetupLogin
GO

CREATE PROCEDURE dbo.spSetupLogin
     @windowsSid        varbinary(85)    -- Windows SID of the login we're trying to create
    ,@desiredLoginName  sysname          -- Full Windows user/group name of the login we're trying to create.  This is 
                                         -- only the desired value and if a login already exists with the given SID and a
                                         -- different name, that name will be used instead.
    ,@addToDbRoles  bit = 0              -- Set to 1 if the account has to be added to database read or write roles, otherwise 
	                                 -- only login accounts will be created for the given user
    

AS
    -- *****************************************************************************************************************
    -- Stored Procedure Name:       spSetupLogin
    -- Purpose:                     Procedure to add a login.  This will handle dealing with all the edge cases such as 
    --                              orphaned users/logins and the case where a login already exists under a different 
    --                              name for the SID you're interested in.
    -- Result:                      Any errors from sprocs this calls
    -- *****************************************************************************************************************
	
	
		SET NOCOUNT ON

		DECLARE @loginName          sysname         -- Actual SQL login name as it exists in sys.server_principals
		DECLARE @userName           sysname         -- Actual DB username as it exists in sys.database_principals
		DECLARE @roleID             int             -- The principal ID of the role        
		
		-- See if there is already a login for the SID in question, this may not be using the desired name
		SET @loginName =    (
								SELECT name
								FROM sys.server_principals AS SP
								WHERE SP.sid = @windowsSid
									AND (SP.type = 'U' OR SP.type = 'G')
							)
		IF (@loginName IS NULL)
		BEGIN

			-- Nothing matched the SID, see if we have something matching the name
			
			IF EXISTS   (
							SELECT *
							FROM sys.server_principals AS SP
							WHERE UPPER(SP.name) = UPPER(@desiredLoginName)
								AND (SP.type = 'U' OR SP.type = 'G')
						)
			BEGIN
			
				-- The account is already here, but has the wrong SID; drop it
				RAISERROR('Login exists with wrong SID, droping it...', 0, 1) WITH NOWAIT
				EXEC('DROP LOGIN [' + @desiredLoginName + ']' )        
				
			END    
			
			-- At this point we know that there is no login with the desired name or SID so create it
			RAISERROR('Creating login...', 0, 1) WITH NOWAIT
			EXEC('CREATE LOGIN [' + @desiredLoginName + '] FROM WINDOWS')
			SET @loginName = @desiredLoginName
			
		END

		RAISERROR('Finished login creation phase.', 0, 1) WITH NOWAIT

		-- See if the DB already has a user for this login
		SET @userName = (
							SELECT DP.name
							FROM sys.database_principals AS DP
							WHERE DP.sid = @windowsSid
								AND (DP.type = 'U' OR DP.type = 'G')
						)
		IF (@userName IS NULL)
		BEGIN

			-- No user for this login, now let's be sure we don't have an orphaned user
			
			IF EXISTS   (
							SELECT *
							FROM sys.database_principals AS DP
							WHERE DP.name = @loginName
								AND (DP.type = 'U' OR DP.type = 'G')
						)
			BEGIN
			
				-- The user is orphaned.  We need to reestablish it with its correct sid
				RAISERROR('Remapping orphaned user...', 0, 1) WITH NOWAIT
				EXEC('ALTER USER [' + @loginName + '] WITH LOGIN = [' + @loginName + ']')
				
			END
			ELSE
			BEGIN
			
				RAISERROR('Creating user...', 0, 1) WITH NOWAIT
				EXEC('CREATE USER [' + @loginName + '] FOR LOGIN [' + @loginName + ']')
				
			END
			
			SET @userName = @loginName
			
		END

		RAISERROR('Finished user creation phase.', 0, 1) WITH NOWAIT	
				
		IF (@addToDbRoles = 1)
		BEGIN
			EXEC sp_addrolemember 'db_datareader' , @userName 
			EXEC sp_addrolemember 'db_datawriter' , @userName 

			if (NOT EXISTS(select * from sysusers where name = N'appv_db_executor' AND issqlrole = 1))
			BEGIN
				CREATE ROLE appv_db_executor
				GRANT EXECUTE TO appv_db_executor
			END

			EXEC sp_addrolemember 'appv_db_executor' , @userName 
		END	

GO

-- End: spSetupLogin
