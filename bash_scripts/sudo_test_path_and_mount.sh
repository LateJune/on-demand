#!/bin/bash

source .env
mount_path="/mnt/landfill"
share_ip="x.x.x.x"

while
	(( $(ls $mount_path | wc --words) <= 0 ))
do 

	printf "[+] Attempting to mount\n"
	echo "$su_pass" | sudo -S mount -v -t cifs -o username=June,password=$share_pass //$share_ip/Landfill /mnt/landfill 
	
	printf "[.]Sleeping for 5 seconds\n"
	sleep 5

done

printf "[+] $mount_path has $(ls $mounth_path | wc --words) words present\n"
printf "[+] Exiting execution\n"

