#!/bin/bash

source .env

while
	
	if [[ $(ls /tmp | grep .b64| wc --words) > 0 ]]
		then
			printf "[+] Grep found $(ls /tmp | grep .b64| wc --words) files in /tmp. Moving to $final_path\n"
			ls /tmp | grep .b64 | sudo xargs -r -I{} mv /tmp/{} $final_path
		else
			printf "[+] Moving to mnt\n"
	fi
do
if [[ -f "$mount_path/flag" && $(ls $mount_path | wc --words) > 0 ]]
	then
		printf "[+] Flag is present in the path and number of words are greater than zero, attempting to unmount the share\n"
		echo "$su_pass" | sudo umount $mount_path -l

		if [[ $(ls $mount_path | wc --words) = 0 ]]
			then
				printf "[+] unmount successful! $mount_path has $(ls $mount_path | wc --words) words present\n"

			else
				printf "[x] unmount was unsuccessful" 
		fi

		printf "[-] Sleeping for 5 seconds\n"
		sleep 5

else
	printf "[+] Flag is not present and number of words are more than zero, running the mount portion\n"
	while
		# Check if anything is mounted
		# if mount was successful, then the number of words returned will not be zero
		(( $(ls $mount_path | wc --words) <= 0 ))
	do 

		printf "[+] Attempting to mount\n"
		echo "$su_pass" | sudo -S mount -v -t cifs -o username=$user,password=$share_pass,port=$port //$share_ip/$mount_folder $mount_path 
		
		if [[ $(ls $mount_path | wc --words) > 0 ]]
			then
				printf "[+] Mount was successful! $mount_path has $(ls $mount_path | wc --words) words present\n"
			else
				printf "[x] Mount was unsuccessful" 
		fi 
		printf "[-] Sleeping for 5 seconds\n"
		sleep 5
	done
fi 
printf "[+] Exiting execution\n"
printf "[-] Sleeping for 5 seconds\n"
sleep 5
done
exit main loop