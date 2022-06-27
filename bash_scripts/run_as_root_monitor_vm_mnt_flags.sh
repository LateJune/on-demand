#!/bin/bash

source .env

while 
    ssh_value=$(ps -auxf | grep ssh | grep -v ssh-agent | grep -v grep | wc --lines)
    mount_value=$(ls $mount_path | wc --words) 
    share_unmount_flag_value=$( test -f "$mount_path/flag"; echo $?)
    active_session_flag_value=$( test -f "/tmp/flag"; echo $?)

    printf "\nssh_value: $ssh_value (1==false, 1>true)\n"
    printf "mount_value: $mount_value (0==false, 1>=true)\n"
    
    printf "share_unmount_flag_value: $share_unmount_flag_value (1==false, 0==true)\n"
    printf "active_session_flag_value: $active_session_flag_value (1==false, 0==true)\n\n"
    
	if [[ $(ls /tmp | grep .b64| wc --words) > 0 ]]
		then
			printf "[+] $(ls /tmp | grep .b64| wc --words) New .b64 files in /tmp. Moving to $final_path\n"
			ls /tmp | grep .b64 | sudo xargs -r -I{} mv /tmp/{} $final_path
		else
			printf "[x] No new files in /tmp\n"
	fi

do
    # Base case, idling
    # Ssh'd user is not present, and no active session
    if [[ $ssh_value -le 2 && $active_session_flag_value -eq 1 ]]
        then
            printf "[+] Ssh'd user is not true, no active session. Continuing\n" 
            printf "[-] Sleeping 5\n"
            sleep 5
            

    # elif ssh session is false, active session flag is true, mount value is false    
    elif [[ $ssh_value -le 2 && $active_session_flag_value -eq 0 && $mount_value -eq 0 ]]
        then
            printf "[+] Ssh session is not present, active session flag in /tmp/flag is present, removing /tmp/flag\n"
            printf "[-] Turning off and restoring vm\n"
            printf "[-] Sleeping 5\n"
            sleep 5
            
    # elif ssh session is true, active session value is true, mount value is false
    elif [[ $ssh_value -ge 3 && $active_session_flag_value -eq 0 && $mount_value -eq 0 ]]
        then
            printf "[+] Normal operations, ssh session is true, active session flag is true, mount is false\n" 
            printf "[-] Sleeping 5\n"
            sleep 5


    # elif ssh'd is true, active session flag is false, mounted is false, share unmount flag is false 
    elif [[ $ssh_value -ge 3 && $active_session_flag_value -eq 1 && $mount_value -eq 0 && $share_unmount_flag_value -eq 1 ]]
        then 
            printf "[+] Starting VM headlessly\n"
            printf "[+] Mounting\n"
            printf "[+] Creating active session flag in /tmp/flag\n"
            printf "[-] Sleeping 5\n"
            sleep 5

    # elif mount is true, share unmount flag is true
    elif [[ $mount_value -gt 0 && $share_unmount_flag_value -eq 0 ]]
        then
            printf "[+] flag is present and share is mounted\n"
            # if ssh is true and active session is true
            if [[ $ssh_value -ge 3 && $active_session_flag_value -eq 0 ]] 
                then
                printf "[+] Unmounting share on flag present and ssh is active\n"
                
            # fail safe   
            else
                printf "[+] SSH is not active, share is still mounted and flag present....unmounting, turning off vm and restoring\n"

            fi 
            printf "[-] Sleeping 5\n"
            sleep 5
    # elif active session is true, unmount flag present is false, mount is true, and ssh session is true
    elif [[ $active_session_flag_value -eq 0 && $share_unmount_flag_value -eq 1 && $mount_value -gt 0  && $ssh_value -ge 3 ]]
        then
            printf "[+] Session active flag is true, unmount flag is not present, mount status is true, ssh'd user is present\nNormal active operations, continuing\n"
            printf "[-] Sleeping 5\n"
            sleep 5

    else
        printf "[x] Reached else clause, something unexpected happened\n"
        printf "[x] Checking VM status, Checking mnt status, removing session /tmp/flag\n"
        printf "[-] Sleeping 5"
        sleep 5
    fi
done


    