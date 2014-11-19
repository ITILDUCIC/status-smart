#!/bin/bash
_username=$(whoami);
echo $_username;
 
#
# input_file ,  file containing the multiple URIs whose status is required.
# output_file,  file to which the header from the URIs and the response time
#                               would be written to.
#
 
input_file=/home/$_username/Desktop/input.txt                   # Change path to the path of your input file.
output_file=/home/$_username/Desktop/output.txt                 # Change path to the path of your output file.
 
 
function status() {
 
        while IFS=$'\n' read -r data || [[ -n "$data" ]]; do
 
                if [[ "$data" = "" ]]; then
                        continue;
                fi
 
                let count=check;
 
                #
                # count==false => cURL doesn't exist. Continue with wget.
                # count==true  => cURL exists but wget doesn't exist. Continue with cURL.
                #
 
                if [[ "$count" = true ]] ; then
                        curl -sL -w "%{http_code} %{url_effective}\\n" $data -o /dev/null >> $output_file 2>&1;
                        curl -sL -w %{time_total}\\n -o /dev/null $data >> $output_file 2>&1;
                elif [[ "$count" = false ]]; then      
                        wget -S --spider $data 2>&1 | awk '/^  /';
                else   
                        curl -sL -w "%{http_code} %{url_effective}\\n" $data -o /dev/null >> $output_file 2>&1;
                        curl -sL -w %{time_total}\\n -o /detextv/null $data >> $output_file 2>&1;
                fi
 
                #awk '{i += (length() + 1); if (i <= 10000) print $ALL}' output.txt
 
        done <$input_file
        echo "Status recorded in file: /home/$_username/Desktop/output.txt"
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
 
status
echo "Process Completed."