******************************************************************
Before you install and use the Application Virtualization Database Scripts you must:
1.	Review the Microsoft Application Virtualization Server 5.0 license terms.
2.	Print and retain a copy of the license terms for your records.
By running the Microsoft Application Virtualization Database Scripts you agree to such license terms.  If you do not accept them, do not use the software.
******************************************************************


Steps to install "AppVManagement" schema in SQL SERVER.


PREREQUISITES:
-------------------------------------------------------------------------------
 1. Review the installation package.  The following files MUST exist:

    SQL files
    ---------
    Database.sql
    CreateTables.sql
    CreateStoredProcs.sql
    UpdateTables.sql
    InsertVersionInfo.sql
    Permissions.sql

 2. Ensure the target SQL Server instance and SQL Server Agent service are running.

 3. If you are not running the scripts directly on the server, ensure the 
    necessary SQL Server client software is installed and available from
    the specified location.  Specifically, the "osql" command must
    be supported for these scripts to run.
-------------------------------------------------------------------------------


PREPARATION:
-------------------------------------------------------------------------------
 1. Review the database.sql file and modify as necessary.  Although the
    defaults are likely sufficient, it is suggested that the following
    settings be reviewed:

    DATABASE - ensure name is satisfactory - default is "AppVManagement".   

 2. Review the Permissions.sql file and provide all the necessary account information
    for setting up read and write access on the database. Note: Default settings
    in the file will not work.
-------------------------------------------------------------------------------


INSTALLATION:
-------------------------------------------------------------------------------
 1. Run the database.sql against the "master" database.  Your user 
    credential must have the ability to create databases.
    This script will create the database.

 2. Run the following scripts against the "AppVManagement" database using the 
    same account as above in order.

    CreateTables.sql
    CreateStoredProcs.sql
    UpdateTables.sql
    InsertVersionInfo.sql
    Permissions.sql 
-------------------------------------------------------------------------------
