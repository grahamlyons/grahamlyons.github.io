---
layout: post
title: Using Python to delete old files and keep newest ones
permalink: /article/using-python-to-delete-old-files-and-keep-newest-ones
date: 2010-09-30
---

This is a very simple Python script which searches a directory, optionally including a file pattern, and deletes the oldest files.

I hear a lot about Python - it seems to be very popular - so when I needed to automatically delete some old backup files I thought I'd have a go at using it.

This code is very simple: its searches a file path, looks at the last modification time of the files, sorts them accordingly and then deletes all but the newest ones. The file path can also include a file pattern, e.g. ```fpath='/Users/fred/backup/*.tar'``` or ```fpath='C:\\\\BACKUP\\\\db*.zip'```

The ```os.stat()```  method gives us information about a file. Loop over the files and for each one get the modification time and sort it in a map.

    fileData = {}
    for fname in fileDir:
        fileData[fname] = os.stat(fname).st_mtime

Sort this new map according to the modification time we stored.

    sortedFiles = sorted(fileData.items(), key=itemgetter(1))

Then loop over the files and remove each one, stopping ```keep``` places before the end.

    delete = len(sortedFiles) - keep
    for x in range(0, delete):
        os.remove(sortedFiles[x][0]

I use a .sh or .bat file to run this with either a cron job or a scheduled task.

I've put the full file in a repository on Github: http://github.com/grahamlyons/delete-old-files
