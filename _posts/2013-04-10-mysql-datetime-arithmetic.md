---
layout: post
title: Correctly Handling Timestamp Arithmetic in MySQL
date: 2013-04-10
permalink: /article/correctly-handling-timestamp-arithmetic-in-mysql
---

Working with dates and times in databases, and even software in general, can be tricky. Different timezones and formats to parse are all pitfalls waiting to trip up the unwary engineer. MySQL is a widely used database and in its default configuration is very forgiving. This certainly contributes to its popularity but unfortunately lays some traps for those of us who are careless.

I was tripped up by MySQL's leniency when I tried to insert a value representing an expiry time into a column in the database. This was a time in the future so I wanted to calculate it from the current time, plus some arbitrary number of seconds. I fired up the mysql console and, using the ```test``` database, tried this:

    mysql> CREATE TABLE `test` (`time` DATETIME);
    mysql> INSERT INTO `test` VALUES(CURRENT_TIMESTAMP + 10);

    mysql> SELECT * FROM `test`;
    +---------------------+
    | time                |
    +---------------------+
    | 2013-04-07 11:49:52 |
    +---------------------+
    1 row in set (0.01 sec)

All looks to be working fine; that was easy! It was only when there started to be intermittent errors in the application that I had to look a little more closely...

## Invalid Dates

It turns out that this works fine when the integer that you add doesn't cause the number of seconds to go above 60 i.e. into the next minute. For example, adding ```10``` when the current time is ```2013-04-07 11:49:42``` gives ```2013-04-07 11:49:52```, which is correct. However, if the current time were ```2013-04-07 11:49:52``` and we added ```10``` to it we get something invalid which is then coerced into a ```DATETIME``` column. In debugging this I ran the ```INSERT```/```SELECT``` in a loop until I saw the problem, like this:

    $ while true; do echo 'INSERT INTO `test` VALUES(CURRENT_TIMESTAMP + 10); \
      SELECT * FROM `test`;' | mysql -u root test; sleep 5; done
    ...
    time
    2013-04-07 12:11:47
    2013-04-07 12:11:53
    2013-04-07 12:11:58
    0000-00-00 00:00:00
    0000-00-00 00:00:00
    2013-04-07 12:12:13
    2013-04-07 12:12:19

It appeared to be once the current time got to the end of a minute that the value suddenly appears as ```0000-00-00 00:00:00```. Looking more closely at what's happening before it goes into the column it looks something like this:

    $ echo 'SELECT CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + 10' | mysql -u root test
    CURRENT_TIMESTAMP       CURRENT_TIMESTAMP + 10
    2013-04-07 12:22:51     20130407122261.000000

For some reason the timestamp is reformatted to remove all the spaces, dashes and colons and the seconds part - the two digits just to the left of the decimal point - is now invalid: ```61```. When an invalid date is inserted into a ```DATETIME``` column, by default, MySQL will convert it to ```0000-00-00 00:00:00``` and generate a warning (it's mentioned in the SQL mode documentation under [ALLOW\_INVALID\_DATES](http://dev.mysql.com/doc/refman/5.5/en/server-sql-mode.html#sqlmode_allow_invalid_dates), but more on SQL mode later).

## Use the Date/Time Functions

The solution here is to use a proper function to do the arithmetic on the timestamp value - ```DATE_ADD``` or ```TIMESTAMPADD``` would work; run ```help <function name>``` in a ```mysql``` prompt to get usage instructions.

Another possibility is to use the ```INTERVAL``` keyword along with the appropriate date part, in this case ```SECOND``` e.g.:

    mysql> INSERT INTO `test` VALUES(CURRENT_TIMESTAMP + INTERVAL 10 SECOND);

## Guarding Against it with SQL Mode

It seems here that MySQL is too lenient with what it'll accept. It would have been better to throw an error and not accept the invalid date at all. Fortunately, the server can be configured to do that by setting the [SQL mode](http://dev.mysql.com/doc/refman/5.5/en/server-sql-mode.html). Running the following will prevent the invalid date from ending up in the database at all:

    mysql> SET SESSION sql_mode='NO_ZERO_DATE,STRICT_ALL_TABLES';
    Query OK, 0 rows affected (0.00 sec)

So now (for this session at least) when we try to insert an invalid date:

    mysql> INSERT INTO `test` VALUES(CURRENT_TIMESTAMP + 60);
    ERROR 1292 (22007): Incorrect datetime value: '20130410073762' for column 'time' at row 1

The mode can be set globally in the MySQL config file: ```my.cnf``` or ```my.ini```, depending on your system. Exactly what mode you use will depend on how you're using your database.
