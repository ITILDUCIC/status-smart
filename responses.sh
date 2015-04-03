#!/bin/bash
_username=$(whoami);
echo $_username;
user_count=0

sudo service redis_6379 start

function status() {
	
	while IFS=$'\n' read -r user || [[ -n "$user" ]]; do
		
		redis-cli HDEL user:"$user" url
		redis-cli HDEL user:$user:$url_count timestamp url header response parent
		redis-cli HGETALL user:$user

		url_count=(`redis-cli HGET registered_user:$user url_count`)
		name=`redis-cli HGET registered_user:$user user_name`;

		redis-cli HGETALL user:"$user"
		redis-cli HGETALL user:$user:$url_count
		((user_count+=1))
		echo "user:$user_count"
		echo "user:$user"

		i=0;
		for (( i = 0; i < $url_count ; i++ )); do
			url=`redis-cli HGET registered_user:$user url:"$i"`;
			echo $url;
			let count=check;

			#
			# count==false => cURL doesn't exist. Continue with wget.
			# count==true  => cURL exists but wget doesn't exist. Continue with cURL.
			# else, both exist so continue with cURL
			#
			if [[ "$count" = true ]] ; then
				timestamp=$(date +'%d/%m/%Y %H:%M:%S:%3N')
				header=$(curl -sL -w "%{http_code} %{url_effective}" $url -o /dev/null);
				response="$(curl -sL -w %{time_total} $url -o /dev/null)";
				redis-cli HMSET user:"$user" name:"$name" url "user:$user:$i";
				redis-cli HMSET user:$user:$i timestamp "$timestamp" url "$url" header "$header" response "$response" parent "user:$user_count";
				redis-cli RPUSH response:"$user":"$i" $response;
				list_len=`redis-cli LLEN response:"$user":"$i"`;
				echo $list_len;
				last_index=$((list_len-1));
				redis-cli LRANGE response:"$user":"$i" 0 $last_index;
			elif [[ "$count" = false ]]; then
				timestamp=$(date +'%d/%m/%Y %H:%M:%S:%3N')
				header=$(wget -S --spider $url 2>&1 | awk '/^  /');		#not sure about the wget command. CHECK.
				response=$(wget -S --spider $url 2>&1 | awk '/^  /');		#not sure about the wget command. CHECK.
				redis-cli HMSET user:"$user" name:"$name" url "user:$user:$i";
				redis-cli HMSET user:$user:$i timestamp "$timestamp" url "$url" header "$header" response "$response" parent "user:$user_count";
				redis-cli RPUSH response:"$user":"$i" $response;
				list_len=`redis-cli LLEN response:"$user":"$i"`;
				echo $list_len;
				last_index=$((list_len-1));
				redis-cli LRANGE response:"$user":"$i" 0 $last_index;
			else
				timestamp=$(date +'%d/%m/%Y %H:%M:%S:%3N')
				header=$(curl -sL -w "%{http_code} %{url_effective}" $url -o /dev/null)
				response=$(curl -sL -w %{time_total} $url -o /dev/null);
				redis-cli HMSET user:"$user" name:"$name" url "user:$user:$i";
				redis-cli HMSET user:$user:$i timestamp "$timestamp" url "$url" header "$header" response "$response" parent "user:$user_count";
				redis-cli RPUSH response:"$user":"$i" $response;
				list_len=`redis-cli LLEN response:"$user":"$i"`;
				echo $list_len;
				last_index=$((list_len-1));
				redis-cli LRANGE response:"$user":"$i" 0 $last_index;
			fi
		echo "Status Recorded."
		done

		redis-cli HGETALL user:$user:0
		redis-cli HGETALL user:$user:1
	done </home/pragya/projects/status-smart-2/hashes.txt
}

#
# Checks the existance of ping, cURL, wget
# return count.
# count, false => cURL doesn't exist.
# count, true  => cURL exists but wget doesn't.
#

function check() {

	#
	# Check if ping is installed in the system or not.
	# Exit code if ping doesn't exist.
	#

	if [ ! -x /bin/ping ] ; then
		command -v ping >/dev/null 2>&1 || { echo >&2 "Please install ping or set it in your path. Aborting"; exit 1; }
		echo "ping doesn't exist.";
	fi

	#
	# Check for curl and wget in the system.
	# Inform if curl doesn't exist and proceed with wget.
	# Exit if both do not exist.
	#

	if [ ! -x /usr/bin/curl ] ; then
		command -v curl >/dev/null 2>&1 || { echo >&2 "Please install curl or set it in your path."; }
		echo "curl doesn't exist.";
		let count=false;
	elif [ ! -x /usr/bin/wget ] ; then
		command -v wget >/dev/null 2>&1 || { echo >&2 "Please install wget or set it in your path. Aborting."; exit 1; }
		echo "curl exists but wget doesn't exist";
		let count=true;
	elif [[ ! -x /usr/bin/curl && ! -x /usr/bin/wget ]]; then
		echo "Cannot proceed without cURL and wget. Please install either to continue. Aborting."
		exit 1;
	else
		echo "Program can proceed";
	fi

	return $count;
}

function mean() {

	list_len=0.0;
	sum=0.0;
	ele=0.0;

	while IFS=$'\n' read -r user || [[ -n "$user" ]]; do
		url_count=`redis-cli HGET registered_user:$user url_count`;
		for (( i = 0; i < $url_count; i++ )); do
			sum=0.0;
			list_len=`redis-cli LLEN response:"$user":"$i"`;
			echo $list_len;
			j=0;
			for (( j = 0; j < $list_len; j++ )); do
				ele=`redis-cli LPOP response:$user:$i`;
				echo $ele;
				sum=`bc <<< $sum+$ele`
				echo $sum;
			done
			mean=`bc <<< $sum/$list_len`
			echo $mean
			redis-cli HSET user:$user:$i mean_response "$mean";
		done
		redis-cli HGETALL user:$user:0;
		redis-cli HGETALL user:$user:1;
	done </home/pragya/projects/status-smart-2/hashes.txt
}

status
echo "Process Completed."
mean