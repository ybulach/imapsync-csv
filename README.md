imapsync-csv
========

PRESENTATION
------------
This script allows mass copy of mails between IMAP servers. It uses imapsync and gets the list of emails accounts from csv files.

INSTALLATION
------------
To use this script, you will need [imapsync](https://github.com/imapsync/imapsync). To install it, you can use this (tested on Debian 7 amd64):

	$ cd /usr/local/bin
	$ wget https://raw.github.com/imapsync/imapsync/master/imapsync
	$ apt-get install libunicode-string-perl libmail-imapclient-perl libterm-readkey-perl libio-socket-ssl-perl libdigest-hmac-perl liburi-perl libfile-copy-recursive-perl libio-tee-perl
	$ chmod +x imapsync

You should make sure /usr/local/bin is in your `$PATH` variable.

Then, you can download this GIT repo as ZIP and install **imapsync-csv** in a folder:

	$ cd /home/user
	$ unzip imapsync-csv.git
	$ mv imapsync-csv.git imapsync-csv

Write permissions are needed in the **errors/**, **logs/** and **migrations/** folders. You may want to only allow access of **errors/** and **imapsync.csv** to you, as they will contain plain passwords:

	$ chmod 700 errors -R
	$ chmod 755 logs migrations -R
	$ chmod 700 imapsync.csv

USAGE
-----
The `imapsync.sh` file is the script itself. The folders are used to:

* **errors/**: per-day CSV file with accounts that returned errors
* **logs/**: per-day full imapsync log
* **migrations/**: per-user/per-day imapsync errors.

The **imapsync.csv** file needs to be filled with accounts (one per line) to sync, with this values (semi-colon separated):

* user login on source server.
* user password on source server.
* user login on destination server. If empty, the same login as source will be used.
* user password on destination server. If empty, the same password as source will be used.
* source folder
* destination folder

This file will look like this:

	admin@test.com;srcPa$$;newaccount@test.com;pass;INBOX;
	user@mydomain.com;Password;;;;Temp

All other columns will be ignored. That allow you to copy one of the CSV file in **errors/** and relaunch a sync:

	$ cp errors/2014-01-29.csv imapsync.csv

Before launching `imapsync.sh`, you need to edit the **imapsync.conf** file.

* **authx** expects imapsync arguments for authentication (**--sslx**, **--authmechx**, etc.)
* **domainx** can be filled if all users are in the same domain and if the source/destination server expects full email address for authentication
* **globalpass** can be filled with a global password, if the destination server allows password overwrite (through a specific plugin for example)
* **dryrun** allows execution of the scripts and imapsync without applying modifications, for example to check authentication of users

Then to sync emails:

	$ ./imapsync.sh

You should launch this in `screen` to prevent sync being stopped in case of network/SSH temporary failure.
