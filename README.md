# Task Control and Management

TCM is an automation tool to control and manage the file tasks and store the processing info to the database for the further usages including reports, alerts and notifications.

## Language

The main language is Perl for Sun UNIX and SQL for Oracle 9.x.

## Installation

1. Run the sql script in the install directory which will create the tables required by TCM.
2. Run the configure.pl in the install directory to deploy and generate the installation report.

## Configuration

The configuration file is config.ini in the config directory which is for TCM settings.

## Test and Run

TCM currently implements Test Harness for automation installation, sanity checking and tests. 

## Log

[20170817@11:49:50] INFO        01. ==== task control monitor service is running ====
[20170817@11:49:50] WARN        - Empty File: XML_866_2017-05-26_10h38_31_UTC.gz - try #1, waiting for 3 sec
[20170817@11:49:53] WARN        - Empty File: XML_866_2017-05-26_10h38_31_UTC.gz - try #2, waiting for 3 sec
[20170817@11:49:56] WARN        - Empty File: XML_866_2017-05-26_10h38_31_UTC.gz - try #3, waiting for 3 sec
[20170817@11:49:59] WARN        - Empty File: XML_866_2017-05-26_10h38_31_UTC.gz - try #4, waiting for 3 sec
[20170817@11:50:02] WARN        - Empty File: XML_866_2017-05-26_10h38_31_UTC.gz - try #5, waiting for 3 sec
[20170817@11:50:05] ERR File XML_866_2017-05-26_10h38_31_UTC.gz is empty
[20170817@11:50:06] INFO        mail sent to: joe.chiu@tpg.com.au
[20170817@11:50:06] INFO        02. -- TCM transactions start (3.7e-05s)
[20170817@11:50:06] INFO        03.     moving files (15.179015s)
[20170817@11:50:06] OK          04.     1 files transferred! marking flag and dumping data (0.001151s)
[20170817@11:50:06] INFO        05.     db transactions (0.001891s)
[20170817@11:50:06] INFO        - ID 127: empty XML file - XML_866_2017-05-26_10h38_31_UTC.gz
[20170817@11:50:06] INFO        06.     processing missing and found files (0.37443s)
[20170817@11:50:06] INFO        07.     printing column counter status: 
[20170817@11:50:06] INFO         .      total collected: 1
[20170817@11:50:06] INFO         .      total tcmfile: 0
[20170817@11:50:06] INFO         .      total tcmdump: 1
[20170817@11:50:06] INFO         .      total tcmstat: 1
[20170817@11:50:06] INFO         .      total empty: 1
[20170817@11:50:06] INFO         .      total load: 0
[20170817@11:50:06] INFO         .      total invalid: 0
[20170817@11:50:06] INFO         .      total pass: 0
[20170817@11:50:06] INFO         .      total ignored: 0
[20170817@11:50:06] INFO         .      total found: 0
[20170817@11:50:06] INFO         .      total missing: 0
[20170817@11:50:06] INFO        08. -- TCM transactions end (15.557062s)


## Contributors

You are free to update these tools to make them more helpful.

## License

A short snippet describing the license (MIT, Apache, etc.)
