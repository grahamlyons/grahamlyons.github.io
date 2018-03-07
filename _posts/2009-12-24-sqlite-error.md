title: SQLite General Error 14
date: 2009-12-24
url_code: sqlite-general-error-14

Recently I got a 'General Error 14' message when I tried to write to an SQLite database...

It took me a while to find the answer to this but fortunately it's incredibly simple. The folder that the database file is in needs to have write access for the process that's writing to the database, not just the file itself. And that's it!
