The scripts will assume the following folder structure
\Global Repository
	\SharePoint2013 - INSTALL_MEDIA_LOCATION
		\InstallMedia - the content of the isntall media will be extracted here
			\PrerequisiteInstallerFiles	- location of the prerequisite files


-- COPY
net use z: \\10.0.1.204\deploy /user:broker\mkrynina
robocopy \\tsclient\C\Projects\CSC\MyWorkStyle\Projects\\SPInstallmedia z:/SharePoint2013
cp \\tsclient\C\Projects\CSC\MyWorkStyle\Projects\Downloads\PreReqs\SharePoint2013\*.zip z:/SharePoint2013



C:\Projects\CSC\MyWorkStyle\Projects\SPInstallmedia