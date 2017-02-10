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

# Dry run
if [ -n "$dryrun" ]; then
	extra_args=$extra_args" --dry"
fi

{ while IFS=';' read user1 pass1 user2 pass2 prefix1 prefix2 null; do
	if [ -z "$user1" ]; then
		continue
	fi
	
	# User1 (required)
	user1_full=$user1
	if [ -n "$domain1" ]; then
		user1_full=$user1_full$domain1
	fi
	
	# User2 (optional)
	user2_full=$user2
	if [ -z "$user2" ]; then
		user2_full=$user1
	fi
	
	if [ -z "$pass2" ]; then
		pass2=$pass1
	fi
	
	if [ -n "$domain2" ]; then
		user2_full=$user2_full$domain2
	fi
	
	# Prefixes (optional)
	if [ -n "$prefix1" ]; then
		local_args=$local_args" --folderrec '$prefix1'"
		new_prefix1=$(echo $prefix1 | sed 's/\//\\\//g')
		if [ -n "$prefix2" ]; then
		    new_prefix2=$(echo $prefix2 | sed 's/\//\\\//g')
			local_args=$local_args" --regextrans2 's/^$new_prefix2\/$new_prefix1/$new_prefix2/'"
		else
			local_args=$local_args" --regextrans2 's/^$new_prefix1//'"
		fi
	fi
	
	if [ -n "$prefix2" ]; then
		local_args=$local_args" --prefix2 '$prefix2/'"
	fi
	
	# Users count
	user_current=$(($user_current + 1))
	
	# User import log
	if [ -d $user_logdir ]; then
		mkdir -p $user_logdir"/"$user1_full
	fi
	user_logfile=$user_logdir"/"$user1_full"/`date +%Y-%m-%d`.log"
	
	date=`date +%x_-_%X`
	echo "[$date] Starting $user1_full to $user2_full... $user_current/$user_nb" | tee -a $logfile
	
	# Overwrite pass
	if [ -n "$globalpass1" ]; then
		pass1=$globalpass1
	fi
	
	if [ -n "$globalpass2" ]; then
		pass2=$globalpass2
	fi
	
	# Booyah
	imapsync="imapsync --nosyncacls --syncinternaldates --skipsize --nofoldersizes --allowsizemismatch --idatefromheader --reconnectretry1 20 --reconnectretry2 20 $extra_args $local_args \
		--host1 $host1 --port1 $port1 --user1 $user1_full --password1 $pass1 $auth1 \
		--host2 $host2 --port2 $port2 --user2 $user2_full --password2 $pass2 $auth2 \
		--useheader Date --useheader Subject \
		--exclude '^Bo&AO4-tes partag&AOk-es' --exclude '^Boîtes partagées' --exclude '^Dossiers partagés' --exclude '^Outbox' --exclude '^Junk' --exclude '^Autres utilisateurs' \
		--regexmess 's/>From /X-om:/' \
		--regextrans2 's/^INBOX\///' --regextrans2 's/^Deleted Messages/Trash/' --regextrans2 's/^Corbeille/Trash/' --regextrans2 's/^Sent Messages/Sent/' --regextrans2 's/^Envoyés/Sent/' \
		--regextrans2 's/\(//' --regextrans2 's/\)//' 2>&1 >> $user_logfile"
	imapsync=$(eval $imapsync)
	return=$?
	
	echo "$imapsync" | tee -a $user_logfile >> $logfile
	
	# Log result
	if [ -n "$dryrun" ]; then
		echo $imapsync
		echo "[=====================] DRYRUN ($user1_full to $user2_full)" | tee -a $logfile
	elif [ $return -ne 0 ]; then
		echo "[=====================] ERROR ($user1_full to $user2_full) Return code: $return" | tee -a $logfile
		echo "$user1;$pass1;$user2;$pass2;$prefix1;$prefix2;$return" >> $errorfile
	else
		date=`date +%x_-_%X`
		echo "[$date] SUCCESS ($user1_full)" | tee -a $logfile
	fi
done ; } < $csvfile

date=`date +%x_-_%X`
echo "[$date] IMAPSync Finished." >> $logfile
echo "------------------------------------" >> $logfile
echo "" >> $logfile
