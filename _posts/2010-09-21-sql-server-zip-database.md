---
layout: post
title: SQL Server task to backup and zip a database
date: 2010-09-21
permalink: /article/sql-server-task-to-backup-and-zip-a-database
---

SQL server doesn't support backup compression before version 2008 so here's a script to backup and zip a database.

Keeping on top of database backups is more than prudent, it's pretty much fundamental in most cases. I was recently writing a task in Windows to backup a database in SQL Server 2005. The database is pretty big and it was to be transferred to a remote backup service so I wanted to compress it as well.

Creating a backup task is very simple using SQL Server Management Studio but zipping afterwards turned out to be a bit trickier than I'd hoped because I couldn't find any way to get the name of the backup file to compress.

To get round that I wrote a script which would backup the database and then zip the file all in one. The name of the backup is parameterised so it was much easier to reference it to zip up.

The script is pretty simple and there were only a couple of things which gave me some grief.

First declare and set the parameters e.g. the directories to put the database backup and the zip archive into, plus the name of the database backup file using the current date. This last bit turned out to be a bit tricky and involves using the SQL ```CONVERT``` function, stringing together a couple of date formats and then replacing any undesirable characters, in this case a colon.

    -- Set the name of the database.
    DECLARE	@dbname NVARCHAR(1024)
    SET	@dbname = 'EXAMPLE'

    -- Set the name of the archive backup directory.
    DECLARE	@bakdir VARCHAR(300)
    SET	@bakdir = 'C:\\Backup\\'

    -- Set the name of the database backup directory.
    DECLARE	@dbbakdir VARCHAR(300)
    SET	@dbbakdir = 'C:\\tmp\\' + @dbname

    -- Create the name of the backup file from the database name and the current date.
    DECLARE	@bakname VARCHAR(300)
    SET	@bakname = @dbname + '_backup_' + 
    REPLACE(CONVERT(VARCHAR(20), GETDATE(), 112) + 
    CONVERT(VARCHAR(20), GETDATE(), 108),':','')

    -- Set the name of the backup file.
    DECLARE	@filename VARCHAR(300)
    SET	@filename = @dbbakdir + '\\' + @bakname+'.bak'

Create the necessary directories and backup the database.

    -- Create the directories if necessary.
    EXECUTE	master.dbo.xp_create_subdir @dbbakdir
    EXECUTE	master.dbo.xp_create_subdir @bakdir

    -- Backup the database.
    BACKUP DATABASE @dbname
    TO  DISK = @filename
    WITH NOFORMAT, NOINIT,  NAME = @bakname, SKIP, REWIND, NOUNLOAD,  STATS = 10

Then configure SQL Server to allow you to turn on advanced options, then turn on the â€˜xp_cmdshell' advanced option - this allows you to run commands via the command line.

    -- Turn on the 'xp_cmdshell' function.
    EXEC sp_configure 'show advanced options', 1
    RECONFIGURE
    EXEC sp_configure 'xp_cmdshell', 1
    RECONFIGURE

Build the variable which holds the command to execute - if you use something other than the WinZip command line utility e.g. the 7-Zip command line utility (because that's free) then you'd need to alter the syntax here. The syntax for WinZip is: ```wzzip -a zipfile originalfile```

    -- Build the command line string to add the file to the ZIP archive.
    DECLARE	@cmd VARCHAR(300)
    SET	@cmd = 'wzzip -a '' + @bakdir + @bakname + '.zip' '' + @filename + '''

    -- Execute the command.
    EXEC xp_cmdshell @cmd

Don't forget to turn off those advanced options afterwards.

    -- Turn off the 'xp_cmdshell' function.
    EXEC sp_configure 'xp_cmdshell', 0
    RECONFIGURE
    EXEC sp_configure 'show advanced options', 0
    RECONFIGURE

I've put the full code up on Github: [http://github.com/grahamlyons/SQL-Server-Backup-and-Zip](http://github.com/grahamlyons/SQL-Server-Backup-and-Zip)
