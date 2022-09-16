#!/bin/bash

### Variables for determining control flow and their default values
# isUserSSHed = False
#? isFileShareAvailable = False
# isFileShareMounted = False 
# isUnmountFlagPresent = False
# isEncodedb64FilePresent = False
# isActiveSandboxSession = False

## Default Behavior - Inactive
# No user SSHed 
# Share unmounted
# VM Paused/Suspended

## Startup Behavior
# User SSHed
# VM Resumed
# Shared mounted
# Looking for .b64 encoded files to transfer

## Unmount Behavior
# User SSHed
# VM Running and Connected
# Share Unmount flag present --> Unmount share
# 

## Active Session Behavior
# User SSHed
# VM Running and Connected
# Share Unmounted
# 

## End of Session Behavior
# User not SSHed - SSH Tunnel ended
# VM Revert to previous running snapshot
#  
# Reset Flags

source .env

while 
    ssh_value=$(ps -auxf | grep ssh | grep -v ssh-agent | grep -v grep | wc --lines)
    mount_value=$(ls $mount_path | wc --words) 
    share_unmount_flag_value=$( test -f "$mount_path/flag"; printf $?)
    active_session_flag_value=$( test -f "/tmp/flag"; printf $?)

    
    #printf "\nssh_value: $ssh_value (1==false, 1>true)\n"
    [[ $ssh_value -gt 1 ]] && printf "\nssh_value: True\n" || printf "\nssh_value: False\n"
    #printf "mount_value: $mount_value (0==false, 1>=true)\n"
    [[ $mount_value -gt 1 ]] && printf "mount_value: True\n" || printf "mount_value: False\n"
    #printf "share_unmount_flag_value: $share_unmount_flag_value (1==false, 0==true)\n"
    [[ $share_unmount_flag_value -eq 0 ]] && printf "share_unmount_flag_value: True\n" || printf "share_unmount_flag_value: False\n"
    #printf "active_session_flag_value: $active_session_flag_value (1==false, 0==true)\n"
    [[ $active_session_flag_value -eq 0 ]] && printf "active_session_flag_value: True\n\n" || printf "active_session_flag_value: False\n\n"
    
    if [[ $mount_value -gt 1 ]] 
        then
	    if [[ $(ls /tmp | grep .b64| wc --words) > 0 ]]
		    then
			    printf "[+] $(ls /tmp | grep .b64| wc --words) New .b64 files in /tmp. Moving to $final_path\n"
			    ls /tmp | grep .b64 | sudo xargs -r -I{} mv /tmp/{} $final_path
		    else
			    printf "[x] No new files in /tmp\n"
	    fi
    fi
do
    # Base case, idling
    # Ssh'd user is not present, and no active session
    if [[ $ssh_value -le 2 && $active_session_flag_value -eq 1 ]]
        then
            printf "[+] Ssh'd user is not true, no active session. Continuing\n" 
            
            sleep 5
            
    # elif ssh session is false, active session flag is true, mount value is false    
    elif [[ $ssh_value -le 2 && $active_session_flag_value -eq 0 && $mount_value -eq 0 ]]
        then
            printf "[+] Ssh session is not present, active session flag in /tmp/flag is present, removing /tmp/flag\n"
            rm /tmp/flag
            printf "[-] Turning off VM\n"
            vboxmanage controlvm "$vm" poweroff
            printf "[-] Sleeping 5\n"
			sleep 5
            printf "[+] Restoring VM\n"
            vboxmanage snapshot "$vm" restore "Sandbox Ready Snapshot" 
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
            vboxheadless --startvm "$vm" &
            printf "[-] Sleeping 5\n"
            sleep 5
            printf "[+] Mounting\n"
            #sshpass -p $su_pass sudo mount -v -t cifs -o username=$user,password=$share_pass,port=$port //$share_ip/$mount_folder $mount_path 
            sudo mount -v -t cifs -o username=$user,password=$share_pass,port=$port //$share_ip/$mount_folder $mount_path 
            printf "[+] Creating active session flag in /tmp/flag\n"
            touch /tmp/flag
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
                sudo umount $mount_path
                if [[ $(ls $mount_path | wc --words) = 0 ]]
				then
					printf "[+] unmount successful! $mount_path has $(ls $mount_path | wc --words) words present\n"

				else
					printf "[x] unmount was unsuccessful normal operations\n" 
			    fi
                
            # fail safe   
            else
                printf "[+] Fail Safe reached. SSH is not active, share is still mounted and flag present... Unmounting, turning off vm and restoring\n"
                sudo umount $mount_path
                if [[ $(ls $mount_path | wc --words) = 0 ]]
				then
					printf "[++] Unmount successful! $mount_path has $(ls $mount_path | wc --words) words present\n"
                    printf "[--] Turning off and restoring vm\n"
                    vboxmanage controlvm "$vm" poweroff
                    printf "[--] Sleeping 5\n"
                    sleep 5
                    printf "[++] Restoring VM\n"
                    vboxmanage snapshot "$vm" restore "Sandbox Ready Snapshot"
				else
					printf "[xX] Unmount was unsuccessful from within the fail safe\n" 
			    fi
            fi 
            printf "[-] Sleeping 5\n"
            sleep 5
    # elif active session is true, unmount flag present is false, mount is true, and ssh session is true
    elif [[ $active_session_flag_value -eq 0 && $share_unmount_flag_value -eq 1 && $mount_value -gt 0  && $ssh_value -ge 3 ]]
        then
            printf "[+] Normal active operations, sleeping 5 and continuing\n"
            sleep 5

    else
        printf "[x] Reached else clause, ssh session closed. Removing session /tmp/flag and unmounting share\n"
        rm /tmp/flag
        sudo umount $mount_path
        if [[ $(ls $mount_path | wc --words) = 0 ]]
			then
				printf "[+++] Unmount successful! $mount_path has $(ls $mount_path | wc --words) words present\n"
                printf "[---] Turning off and restoring vm\n"
                vboxmanage controlvm "$vm" poweroff
                printf "[---] Sleeping 5\n"
                sleep 5
                printf "[+++] Restoring VM\n"
                vboxmanage snapshot "$vm" restore "Sandbox Ready Snapshot"
			else
				printf "[xxx] Unmount was unsuccessful from within the else clause\n" 
		fi

        
        printf "[---] Sleeping 5\n"
        sleep 5
    fi
done


    