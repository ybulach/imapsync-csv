#!/bin/bash
# http://wiki.zimbra.com/wiki/Guide_to_imapsync
# http://linux.die.net/man/1/imapsync
#
# Needed folders:
# - logs/
# - migrations/
# - errors/

DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

# Load the config file
test ! -f $DIR"/imapsync.conf" && echo "No imapsync.conf found" && exit 0
. $DIR"/imapsync.conf"

# Check the dirs
test ! -f $DIR"/imapsync.csv" && echo "No imapsync.csv found" && exit 0
test ! -d $DIR"/logs/" && echo "logs/ directory needed" && exit 0
test ! -d $DIR"/migrations/" && echo "migrations/ directory needed" && exit 0
test ! -d $DIR"/errors/" && echo "errors/ directory needed" && exit 0

# Dirs
logfile=$DIR"/logs/`date +%Y-%m-%d`.log"
user_logdir=$DIR"/migrations/"
csvfile=$DIR"/imapsync.csv"
errorfile=$DIR"/errors/`date +%Y-%m-%d`.csv"

date=`date +%x_-_%X`
echo "------------------------------------" >> $logfile
echo "[$date] IMAPSync started." >> $logfile

# Users count
user_nb=$(wc -l < $csvfile)
user_current=0

{ while IFS=';' read user1 pass1 user2 pass2 null; do
	if [ -z $user1 ]; then
		continue
	fi
	
	# User1 (required)
	user1_full=$user1
	if [ -n $domain1 ]; then
		user1_full=$user1_full$domain1
	fi
	
	# User2 (optional)
	user2_full=$user2
	if [ -z $user2 ]; then
		user2_full=$user1
	fi
	
	if [ -z $pass2 ]; then
		pass2=$pass1
	fi
	
	if [ -n $domain2 ]; then
		user2_full=$user2_full$domain2
	fi
	
	# Users count
	user_current=$(($user_current + 1))
	
	# User import log
	if [ -d $user_logdir ]; then
		mkdir -p $user_logdir"/"$user_full
	fi
	user_logfile=$user_logdir"/"$user_full"/`date +%Y-%m-%d`.log"
	
	date=`date +%x_-_%X`
	echo "[$date] Starting $user1_full to $user2_full... $user_current/$user_nb" >> $logfile
	
	# Overwrite pass
	if [[ -n $globalpass ]]; then
		pass2=$globalpass
	fi
	
	# Dry run
	if [ -n "$dryrun" ]; then
		extra_args="--dry"
	fi
	
	# Booyah
	imapsync --nosyncacls --syncinternaldates --skipsize --nofoldersizes --allowsizemismatch --idatefromheader --reconnectretry1 20 --reconnectretry2 20 $extra_args \
		--host1 $host1 --port1 $port1 --user1 "$user1_full" --password1 "$pass1" $auth1 \
		--host2 $host2 --port2 $port2 --user2 "$user2_full" --password2 "$pass2" $auth2 \
		--exclude '^Bo&AO4-tes partag&AOk-es' --exclude '^Boîtes partagées' --exclude '^Dossiers partagés' --exclude '^Outbox' --exclude '^Junk' --exclude '^Autres utilisateurs' \
		--regextrans2 's/^INBOX\///' --regextrans2 's/^Deleted Messages/Trash/' --regextrans2 's/^Corbeille/Trash/' --regextrans2 's/^Sent Messages/Sent/' --regextrans2 's/^Envoyés/Sent/' 2>> $logfile 1>> $user_logfile
	
	return=$?
	
	# Log result
	if [ -n "$dryrun" ]; then
		echo "[=====================] DRYRUN ($user1_full to $user2_full)"
	elif [ $return -ne 0 ]; then
		echo "[=====================] ERROR ($user1_full to $user2_full) Return code: $return" >> $logfile
		echo "$user1;$pass1;$user2;$pass2;$return" >> $errorfile
	else
		date=`date +%x_-_%X`
		echo "[$date] SUCCESS ($user1_full)" >> $logfile
	fi
done ; } < $csvfile

date=`date +%x_-_%X`
echo "[$date] IMAPSync Finished." >> $logfile
echo "------------------------------------" >> $logfile
echo "" >> $logfile

